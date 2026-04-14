import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { setGlobalOptions } from "firebase-functions/v2";

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

setGlobalOptions({ region: "us-central1" });

export const sendVisitNotification = onDocumentCreated("notificaciones_visita/{notificationId}", async (event) => {
  const snap = event.data;
  if (!snap) {
    console.log("No hay datos asociados al evento.");
    return;
  }
  const notificationData = snap.data();
  const residentUid = notificationData.residentUid; 
  const visitorName = notificationData.visitorName;
  const guardName = notificationData.guardName;

  console.log(`Procesando notificación para Auth UID: ${residentUid}`);

  try {
    const residentsQuery = await db.collection("Residentes")
      .where("uid", "==", residentUid) 
      .limit(1)
      .get();

    if (residentsQuery.empty) {
      console.log("No se encontró ningún residente con ese UID.");
      return;
    }

    const residentDoc = residentsQuery.docs[0]; 
    const residentData = residentDoc.data();
    const token = residentData.fcmToken;

    if (!token) {
      console.log("El residente no tiene token FCM registrado.");
      return;
    }

    const message = {
      token: token,
      notification: {
        title: "Visita en Portería",
        body: `${visitorName} se encuentra en portería (Anunciado por ${guardName}).`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        screen: "notifications",
      },
      android: {
        notification: {
          sound: "default"
        }
      },
      apns: {
        payload: {
          aps: {
            sound: "default"
          }
        }
      }
    };

    await messaging.send(message);
    console.log("Notificación enviada con éxito a:", token.substring(0, 10) + "...");
  } catch (error) {
    console.error("Error al enviar notificación:", error);
  }
});