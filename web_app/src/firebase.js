import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: "AIzaSyAKyH_wLEBxq-kshNMkW3WYZDUCSkwOIdI",
  authDomain: "studyvoice-97608.firebaseapp.com",
  projectId: "studyvoice-97608",
  storageBucket: "studyvoice-97608.firebasestorage.app",
  messagingSenderId: "373669058378",
  appId: "1:373669058378:web:fb4e026c05028e9948d3b3",
  measurementId: "G-JFHRR0NYB9"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const storage = getStorage(app);
