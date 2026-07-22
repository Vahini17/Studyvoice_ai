import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { createUserWithEmailAndPassword, updateProfile } from 'firebase/auth';
import { auth } from '../firebase';
import { Mail, Lock, User } from 'lucide-react';

export default function Signup() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSignup = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      await updateProfile(userCredential.user, { displayName: name });
      navigate('/home');
    } catch (err) {
      setError(err.message.replace('Firebase: ', ''));
    }
    setLoading(false);
  };

  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh', padding: '24px' }}>
      <div style={{ width: '100%', maxWidth: '400px' }}>
        <h1 className="gradient-text" style={{ textAlign: 'center', fontSize: '2.5rem', marginBottom: '8px', fontWeight: 'bold' }}>Create Account 🚀</h1>
        <p style={{ textAlign: 'center', color: 'var(--text-secondary)', marginBottom: '36px' }}>Join StudyVoice and learn faster</p>

        <div className="glass-card" style={{ padding: '24px' }}>
          <form onSubmit={handleSignup} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <label style={{ fontSize: '0.9rem', fontWeight: 'bold', color: 'var(--text-primary)' }}>Full Name</label>
              <div style={{ position: 'relative' }}>
                <User style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }} size={20} />
                <input 
                  type="text" 
                  required
                  placeholder="Enter your name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  style={{
                    width: '100%', padding: '16px 16px 16px 48px', borderRadius: '16px',
                    border: '1px solid var(--glass-border)', background: 'rgba(255,255,255,0.05)',
                    color: 'var(--text-primary)', fontSize: '1rem', outline: 'none'
                  }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <label style={{ fontSize: '0.9rem', fontWeight: 'bold', color: 'var(--text-primary)' }}>Email Address</label>
              <div style={{ position: 'relative' }}>
                <Mail style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }} size={20} />
                <input 
                  type="email" 
                  required
                  placeholder="Enter your email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  style={{
                    width: '100%', padding: '16px 16px 16px 48px', borderRadius: '16px',
                    border: '1px solid var(--glass-border)', background: 'rgba(255,255,255,0.05)',
                    color: 'var(--text-primary)', fontSize: '1rem', outline: 'none'
                  }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <label style={{ fontSize: '0.9rem', fontWeight: 'bold', color: 'var(--text-primary)' }}>Password</label>
              <div style={{ position: 'relative' }}>
                <Lock style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }} size={20} />
                <input 
                  type="password" 
                  required
                  placeholder="Create a password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  style={{
                    width: '100%', padding: '16px 16px 16px 48px', borderRadius: '16px',
                    border: '1px solid var(--glass-border)', background: 'rgba(255,255,255,0.05)',
                    color: 'var(--text-primary)', fontSize: '1rem', outline: 'none'
                  }}
                />
              </div>
            </div>

            {error && <p style={{ color: '#EF4444', fontSize: '0.9rem', textAlign: 'center' }}>{error}</p>}

            <button 
              type="submit" 
              disabled={loading}
              style={{
                background: 'var(--primary-gradient)', color: 'white', padding: '16px', borderRadius: '28px',
                border: 'none', fontWeight: 'bold', fontSize: '1rem', cursor: 'pointer', marginTop: '8px',
                opacity: loading ? 0.7 : 1
              }}
            >
              {loading ? 'Creating Account...' : 'Sign Up'}
            </button>
          </form>
        </div>

        <p style={{ textAlign: 'center', marginTop: '36px', color: 'var(--text-secondary)' }}>
          Already have an account? <Link to="/login" style={{ color: 'var(--primary-color)', fontWeight: 'bold', textDecoration: 'none' }}>Sign In</Link>
        </p>
      </div>
    </div>
  );
}
