// functions/index.js
// Usamos la sintaxis de import de Módulos (ESM)
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { setGlobalOptions } from "firebase-functions/v2";

// Inicializar servicios de Admin
initializeApp();
const db = getFirestore();
const messaging = getMessaging();
// Opcional: Define la región para tus funciones
setGlobalOptions({ region: "us-central1" });

/**
 * Se activa cuando un guardia crea una 'notificacion_visita'
 * y envía una notificación push al residente.
 */

export const sendVisitNotification = onDocumentCreated("notificaciones_visita/{notificationId}", async (event) => {
  const snap = event.data;
  if (!snap) {
    console.log("No hay datos asociados al evento.");
    return;
  }
  const notificationData = snap.data();
  const residentUid = notificationData.residentUid; // Este es el UID de Auth
  const visitorName = notificationData.visitorName;
  const guardName = notificationData.guardName;
  console.log(`Procesando notificación para Auth UID: ${residentUid}`);

  try {
    // --- CORRECCIÓN AQUÍ: USAR QUERY EN LUGAR DE DOC() ---
    const residentsQuery = await db.collection("Residentes")
      .where("uid", "==", residentUid) // Buscamos por el campo 'uid'
      .limit(1)
      .get();

    if (residentsQuery.empty) {
      console.log("No se encontró ningún residente con ese UID.");
      return;
    }
    const residentDoc = residentsQuery.docs[0]; // Tomamos el primer resultado
    const residentData = residentDoc.data();
    const token = residentData.fcmToken;
    // --- FIN DE CORRECCIÓN ---
    if (!token) {
      console.log("El residente no tiene token FCM registrado.");
      return;
    }

    const payload = {
      notification: {
        title: "Visita en Portería",
        body: `${visitorName} se encuentra en portería (Anunciado por ${guardName}).`,
        sound: "default",
      },

      data: {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "screen": "notifications",
      }
    };

    await messaging.sendToDevice(token, payload);
    console.log("Notificación enviada con éxito a:", token.substring(0, 10) + "...");
  } catch (error) {
    console.error("Error al enviar notificación:", error);
  }
});