/**
 * Modified server.ts for Dental Receptionist
 * 
 * This file shows the key modifications needed to integrate the dental receptionist
 * into your existing Nova Sonic server code.
 * 
 * INSTRUCTIONS:
 * 1. Copy the sections marked with "ADD THIS" into your existing server.ts
 * 2. Or replace your entire server.ts with this modified version
 */

import { Server } from 'socket.io';
import express from 'express';
import http from 'http';
import path from 'path';
import { fileURLToPath } from 'url';

// ===== ADD THIS: Import dental receptionist configuration =====
const { DENTAL_RECEPTIONIST_PROMPT } = require('./dental-receptionist-config.js');
// ===============================================================

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Serve static files
app.use(express.static(path.join(__dirname, '../public')));

// ===== ADD THIS: Dental practice info endpoint =====
app.get('/api/practice-info', (req, res) => {
  res.json({
    name: "Your Dental Practice Name",
    phone: "+44 20 XXXX XXXX",
    address: "City Centre, Near Main Market Area",
    hours: "Monday-Saturday, 9 AM - 7 PM",
    emergencyAvailable: true
  });
});
// ====================================================

// Store active sessions
const activeSessions = new Map();

io.on('connection', (socket) => {
  console.log(`Client connected: ${socket.id}`);
  
  // ===== MODIFY THIS: Send dental receptionist prompt on connection =====
  socket.emit('systemPrompt', DENTAL_RECEPTIONIST_PROMPT);
  
  // Also set a default voice suitable for reception (professional female voice)
  socket.emit('voiceConfig', { voiceId: 'tiffany' });
  // ======================================================================
  
  // Initialize session
  activeSessions.set(socket.id, {
    startTime: Date.now(),
    conversationHistory: [],
    patientInfo: {
      name: null,
      phone: null,
      email: null,
      reasonForVisit: null,
      isNewPatient: null
    }
  });

  // ===== ADD THIS: Handle patient information collection =====
  socket.on('patientInfo', (data) => {
    const session = activeSessions.get(socket.id);
    if (session) {
      session.patientInfo = { ...session.patientInfo, ...data };
      console.log(`Patient info updated for ${socket.id}:`, session.patientInfo);
      
      // Optionally save to database here
      // await savePatientInfo(session.patientInfo);
      
      // Acknowledge receipt
      socket.emit('patientInfoReceived', {
        success: true,
        message: 'Information recorded successfully'
      });
    }
  });
  // ============================================================

  // Handle audio streaming
  socket.on('audioStream', async (audioData) => {
    try {
      const session = activeSessions.get(socket.id);
      if (!session) {
        socket.emit('error', { message: 'Session not found' });
        return;
      }

      // Process audio with Nova Sonic
      // Your existing Nova Sonic integration code here
      // The DENTAL_RECEPTIONIST_PROMPT is already set as the system context
      
    } catch (error) {
      console.error('Error processing audio:', error);
      socket.emit('error', { message: 'Failed to process audio' });
    }
  });

  // ===== ADD THIS: Handle appointment scheduling requests =====
  socket.on('scheduleAppointment', async (appointmentData) => {
    try {
      console.log('Appointment request:', appointmentData);
      
      // Here you would integrate with your appointment scheduling system
      // For now, we'll just log and confirm
      
      const appointment = {
        id: `APT-${Date.now()}`,
        patientName: appointmentData.patientName,
        date: appointmentData.date,
        time: appointmentData.time,
        type: appointmentData.type || 'Check-up',
        status: 'pending',
        createdAt: new Date()
      };
      
      // In production, save to database:
      // await saveAppointment(appointment);
      
      socket.emit('appointmentScheduled', {
        success: true,
        appointment: appointment,
        message: 'Appointment scheduled successfully. You will receive a confirmation via SMS and email.'
      });
      
    } catch (error) {
      console.error('Error scheduling appointment:', error);
      socket.emit('appointmentScheduled', {
        success: false,
        message: 'Failed to schedule appointment. Please try again.'
      });
    }
  });
  // ============================================================

  // Handle custom system prompt changes (allow receptionists to update on the fly)
  socket.on('updateSystemPrompt', (customPrompt) => {
    if (customPrompt && typeof customPrompt === 'string') {
      // Optionally, prepend the base prompt with custom instructions
      const updatedPrompt = `${DENTAL_RECEPTIONIST_PROMPT}\n\nADDITIONAL INSTRUCTIONS:\n${customPrompt}`;
      socket.emit('systemPrompt', updatedPrompt);
      console.log(`System prompt updated for ${socket.id}`);
    }
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    console.log(`Client disconnected: ${socket.id}`);
    
    // ===== ADD THIS: Log session summary before cleanup =====
    const session = activeSessions.get(socket.id);
    if (session) {
      const sessionDuration = Date.now() - session.startTime;
      console.log(`Session summary for ${socket.id}:`, {
        duration: `${Math.floor(sessionDuration / 1000)}s`,
        patientInfo: session.patientInfo,
        messageCount: session.conversationHistory.length
      });
      
      // In production, save session logs to database
      // await saveSessionLog(session);
    }
    // =========================================================
    
    activeSessions.delete(socket.id);
  });
});

// ===== ADD THIS: Session cleanup for idle connections =====
const IDLE_TIMEOUT = 5 * 60 * 1000; // 5 minutes

setInterval(() => {
  const now = Date.now();
  activeSessions.forEach((session, socketId) => {
    if (now - session.startTime > IDLE_TIMEOUT) {
      console.log(`Cleaning up idle session: ${socketId}`);
      const socket = io.sockets.sockets.get(socketId);
      if (socket) {
        socket.disconnect();
      }
      activeSessions.delete(socketId);
    }
  });
}, 60 * 1000); // Check every minute
// ============================================================

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`🦷 Dental Receptionist Server running on port ${PORT}`);
  console.log(`🌐 Visit http://localhost:${PORT}`);
  console.log(`📞 Using Dental Receptionist AI with grounded knowledge base`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});
