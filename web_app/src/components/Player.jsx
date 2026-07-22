import React, { useState, useEffect, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Play, Pause, ArrowLeft, Settings, SkipBack, SkipForward } from 'lucide-react';

export default function Player() {
  const location = useLocation();
  const navigate = useNavigate();
  const pdf = location.state?.pdf;

  const [isPlaying, setIsPlaying] = useState(false);
  const [speed, setSpeed] = useState(1.0);
  const [currentWordIndex, setCurrentWordIndex] = useState(0);
  
  const synth = window.speechSynthesis;
  const utteranceRef = useRef(null);

  useEffect(() => {
    if (!pdf) {
      navigate('/home');
      return;
    }

    // Initialize utterance
    const utterance = new SpeechSynthesisUtterance(pdf.textContent);
    utterance.rate = speed;
    
    // Attempt to track boundaries (support varies by browser)
    utterance.onboundary = (e) => {
      if (e.name === 'word') {
        // e.charIndex gives the position in the string
        // For a true accurate highlight, we'd map charIndex to word array
        setCurrentWordIndex(e.charIndex); 
      }
    };

    utterance.onend = () => {
      setIsPlaying(false);
    };

    utteranceRef.current = utterance;

    return () => {
      synth.cancel();
    };
  }, [pdf, navigate]);

  useEffect(() => {
    if (utteranceRef.current) {
      utteranceRef.current.rate = speed;
      // Changing speed while playing usually requires restart on Web Speech API
      // For simplicity, we just set the rate. It applies to the next utterance.
    }
  }, [speed]);

  const togglePlay = () => {
    if (!utteranceRef.current) return;

    if (isPlaying) {
      synth.pause();
      setIsPlaying(false);
    } else {
      if (synth.paused) {
        synth.resume();
      } else {
        synth.speak(utteranceRef.current);
      }
      setIsPlaying(true);
    }
  };

  const handleSpeedChange = () => {
    const nextSpeed = speed === 1.0 ? 1.5 : speed === 1.5 ? 2.0 : 1.0;
    setSpeed(nextSpeed);
    
    // Restart to apply speed immediately if playing
    if (isPlaying) {
      synth.cancel();
      setTimeout(() => {
        const u = new SpeechSynthesisUtterance(pdf.textContent);
        u.rate = nextSpeed;
        u.onend = () => setIsPlaying(false);
        utteranceRef.current = u;
        synth.speak(u);
      }, 100);
    }
  };

  if (!pdf) return null;

  // Split text into lines for display
  const displayLines = pdf.textContent.split('\\n').filter(l => l.trim().length > 0);

  return (
    <div style={{ maxWidth: '600px', margin: '0 auto', minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      
      {/* Header */}
      <div style={{ padding: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-primary)' }}>
          <ArrowLeft size={28} />
        </button>
        <div style={{ textAlign: 'center', flex: 1, padding: '0 16px', overflow: 'hidden' }}>
          <h2 style={{ fontSize: '1.1rem', fontWeight: 'bold', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{pdf.fileName}</h2>
          <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>{pdf.subject}</span>
        </div>
        <button style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-primary)' }}>
          <Settings size={24} />
        </button>
      </div>

      {/* Text Area */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '20px', fontSize: '1.2rem', lineHeight: '1.8' }}>
        {displayLines.map((line, idx) => (
          <p key={idx} style={{ marginBottom: '16px' }}>
            {line}
          </p>
        ))}
      </div>

      {/* Audio Controls */}
      <div className="glass-card" style={{ padding: '24px 20px', borderBottomLeftRadius: 0, borderBottomRightRadius: 0, display: 'flex', flexDirection: 'column', gap: '20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: 'var(--text-secondary)' }}>
          <span style={{ fontSize: '0.9rem' }}>Speed: {speed}x</span>
          <button onClick={handleSpeedChange} style={{ background: 'rgba(255,255,255,0.1)', border: '1px solid var(--glass-border)', borderRadius: '12px', padding: '6px 12px', color: 'var(--primary-color)', fontWeight: 'bold', cursor: 'pointer' }}>
            Change
          </button>
        </div>
        
        <div style={{ display: 'flex', justifyContent: 'space-evenly', alignItems: 'center' }}>
          <button style={{ background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}>
            <SkipBack size={32} />
          </button>
          
          <button onClick={togglePlay} style={{ width: '72px', height: '72px', borderRadius: '50%', background: 'var(--primary-gradient)', display: 'flex', justifyContent: 'center', alignItems: 'center', color: 'white', border: 'none', cursor: 'pointer', boxShadow: '0 8px 16px rgba(99,102,241,0.3)' }}>
            {isPlaying ? <Pause size={36} fill="white" /> : <Play size={36} fill="white" style={{ marginLeft: '4px' }} />}
          </button>
          
          <button style={{ background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}>
            <SkipForward size={32} />
          </button>
        </div>
      </div>

    </div>
  );
}
