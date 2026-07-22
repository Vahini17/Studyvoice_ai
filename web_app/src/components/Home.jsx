import React, { useState, useEffect, useRef } from 'react';
import { auth, storage } from '../firebase';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { LogOut, Flame, Search, Hourglass, FileText, PlayCircle } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { pdfService } from '../pdfService';
import { aiService } from '../aiService';

export default function Home() {
  const navigate = useNavigate();
  const fileInputRef = useRef(null);
  const [stats, setStats] = useState({ streak: 0, time: 0, pdfs: 0 });
  const [recentPdfs, setRecentPdfs] = useState([]);
  const [isUploading, setIsUploading] = useState(false);

  useEffect(() => {
    loadLocalData();
  }, []);

  const loadLocalData = () => {
    const email = auth.currentUser?.email;
    if (!email) return;

    const savedStats = localStorage.getItem(`local_user_data_${email}`);
    if (savedStats) {
      try {
        const data = JSON.parse(savedStats);
        setStats({
          streak: data.streakDays || 0,
          time: data.totalListeningMinutes || 0,
          pdfs: data.totalPdfsUploaded || 0
        });
      } catch(e) {}
    }

    const savedPdfs = localStorage.getItem(`local_pdfs_${email}`);
    if (savedPdfs) {
      try {
        setRecentPdfs(JSON.parse(savedPdfs));
      } catch(e) {}
    }
  };

  const handleLogout = () => {
    auth.signOut();
    navigate('/login');
  };

  const handleFileSelect = async (e) => {
    const file = e.target.files[0];
    if (!file || file.type !== 'application/pdf') return;
    
    setIsUploading(true);
    try {
      // 1. Extract Text
      const { text, pageCount } = await pdfService.extractText(file);
      
      // 2. AI Analysis
      const [summary, keywords, subject] = await Promise.all([
        aiService.generateSummary(text),
        aiService.extractKeywords(text),
        aiService.detectSubject(text)
      ]);

      // 3. Upload to Firebase Storage
      const storageRef = ref(storage, `pdfs/${auth.currentUser.uid}/${Date.now()}_${file.name}`);
      await uploadBytes(storageRef, file);
      const downloadUrl = await getDownloadURL(storageRef);

      // 4. Create PDF Object
      const newPdf = {
        id: Date.now().toString(),
        fileName: file.name,
        fileSize: pdfService.formatBytes(file.size),
        pageCount,
        uploadDate: new Date().toISOString(),
        textContent: text,
        aiSummary: summary,
        keywords,
        subject,
        downloadUrl,
        lastReadPage: 0
      };

      // 5. Update State & LocalStorage
      const email = auth.currentUser.email;
      const updatedPdfs = [newPdf, ...recentPdfs];
      setRecentPdfs(updatedPdfs);
      localStorage.setItem(`local_pdfs_${email}`, JSON.stringify(updatedPdfs));

      const updatedStats = { ...stats, pdfs: stats.pdfs + 1 };
      setStats(updatedStats);
      const savedStats = localStorage.getItem(`local_user_data_${email}`);
      const data = savedStats ? JSON.parse(savedStats) : {};
      data.totalPdfsUploaded = updatedStats.pdfs;
      localStorage.setItem(`local_user_data_${email}`, JSON.stringify(data));

    } catch (err) {
      alert('Upload failed: ' + err.message);
    }
    setIsUploading(false);
    e.target.value = null; // Reset input
  };

  return (
    <div style={{ maxWidth: '600px', margin: '0 auto', padding: '20px 20px 100px 20px', minHeight: '100vh' }}>
      
      {/* Welcome Row */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '28px' }}>
        <div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>Hello, {auth.currentUser?.displayName || 'Student'}! 👋</h2>
          <p style={{ color: 'var(--text-secondary)' }}>Ready to listen and learn today?</p>
        </div>
        <button onClick={handleLogout} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-secondary)' }}>
          <LogOut size={24} />
        </button>
      </div>

      {/* Streak Banner */}
      <div className="glass-card" style={{ padding: '16px 20px', display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '24px' }}>
        <div style={{ background: 'var(--primary-gradient)', width: '48px', height: '48px', borderRadius: '50%', display: 'flex', justifyContent: 'center', alignItems: 'center', color: 'white' }}>
          <Flame size={28} />
        </div>
        <div>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 'bold' }}>{stats.streak}-Day Study Streak!</h3>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            {stats.streak > 0 ? "Awesome job! Keep listening daily." : "Upload your first study PDF to launch a streak!"}
          </p>
        </div>
      </div>

      {/* Search */}
      <div style={{ background: 'var(--card-color)', border: '1px solid var(--glass-border)', borderRadius: '16px', display: 'flex', alignItems: 'center', padding: '0 16px', height: '52px', marginBottom: '28px' }}>
        <Search size={20} color="var(--text-secondary)" />
        <input type="text" placeholder="Search your study PDFs..." style={{ border: 'none', background: 'transparent', outline: 'none', color: 'var(--text-primary)', marginLeft: '12px', width: '100%', fontSize: '1rem' }} />
      </div>

      {/* Stats Dashboard */}
      <div style={{ display: 'flex', gap: '16px', marginBottom: '28px' }}>
        <div style={{ flex: 1, background: 'var(--card-color)', border: '1px solid var(--glass-border)', borderRadius: '20px', padding: '14px 16px', display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div style={{ background: 'rgba(99, 102, 241, 0.12)', padding: '8px', borderRadius: '12px', color: 'var(--primary-color)' }}>
            <Hourglass size={24} />
          </div>
          <div>
            <h3 style={{ fontSize: '1.25rem', fontWeight: '900' }}>{stats.time}m</h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.75rem' }}>Study Time</p>
          </div>
        </div>

        <div style={{ flex: 1, background: 'var(--card-color)', border: '1px solid var(--glass-border)', borderRadius: '20px', padding: '14px 16px', display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div style={{ background: 'rgba(236, 72, 153, 0.12)', padding: '8px', borderRadius: '12px', color: 'var(--secondary-color)' }}>
            <FileText size={24} />
          </div>
          <div>
            <h3 style={{ fontSize: '1.25rem', fontWeight: '900' }}>{stats.pdfs}</h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.75rem' }}>PDF Files</p>
          </div>
        </div>
      </div>

      {/* Recently Uploaded */}
      <h3 style={{ fontSize: '1.25rem', fontWeight: 'bold', marginBottom: '14px' }}>Recently Uploaded 📑</h3>
      {recentPdfs.length === 0 ? (
        <div className="glass-card" style={{ padding: '36px 24px', textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <FileText size={48} color="var(--text-secondary)" style={{ opacity: 0.5, marginBottom: '16px' }} />
          <h4 style={{ fontWeight: 'bold', fontSize: '1.1rem', marginBottom: '8px' }}>No study files yet</h4>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>Tap the + button below to upload your first study PDF material!</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {recentPdfs.slice(0, 3).map((pdf) => (
            <div 
              key={pdf.id} 
              onClick={() => navigate('/player', { state: { pdf } })}
              className="glass-card" 
              style={{ padding: '16px', display: 'flex', alignItems: 'center', gap: '16px', cursor: 'pointer' }}
            >
              <div style={{ background: 'var(--primary-gradient)', width: '52px', height: '52px', borderRadius: '14px', display: 'flex', justifyContent: 'center', alignItems: 'center', color: 'white' }}>
                <PlayCircle size={26} />
              </div>
              <div style={{ flex: 1, overflow: 'hidden' }}>
                <h4 style={{ fontWeight: 'bold', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{pdf.fileName}</h4>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
                  <span style={{ background: 'rgba(99, 102, 241, 0.12)', color: 'var(--primary-color)', fontSize: '0.6rem', fontWeight: 'bold', padding: '2px 8px', borderRadius: '8px' }}>
                    {pdf.subject.toUpperCase()}
                  </span>
                  <span style={{ color: 'var(--text-secondary)', fontSize: '0.75rem' }}>
                    {pdf.pageCount} pages • {pdf.fileSize}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* FAB Upload Button */}
      <input 
        type="file" 
        accept="application/pdf" 
        ref={fileInputRef} 
        onChange={handleFileSelect}
        style={{ display: 'none' }} 
      />
      <button 
        onClick={() => fileInputRef.current.click()}
        disabled={isUploading}
        style={{ position: 'fixed', bottom: '30px', right: '30px', background: 'var(--primary-gradient)', color: 'white', width: '60px', height: '60px', borderRadius: '50%', border: 'none', boxShadow: '0 8px 16px rgba(99, 102, 241, 0.3)', cursor: 'pointer', display: 'flex', justifyContent: 'center', alignItems: 'center', opacity: isUploading ? 0.7 : 1 }}
      >
        <span style={{ fontSize: '32px' }}>{isUploading ? '⏳' : '+'}</span>
      </button>

    </div>
  );
}
