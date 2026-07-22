import { GoogleGenerativeAI } from '@google/generative-ai';

// Same API key as Flutter app
const API_KEY = import.meta.env.VITE_GEMINI_API_KEY || '';
const genAI = new GoogleGenerativeAI(API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

export const aiService = {
  async generateSummary(text) {
    if (!text) return 'No content available to summarize.';
    const truncated = text.length > 2000 ? text.substring(0, 2000) : text;

    try {
      const prompt = `Summarize this study material using bullet points for a student:\n\n${truncated}`;
      
      // Simple timeout wrapper for the API call
      const response = await Promise.race([
        model.generateContent(prompt),
        new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 10000))
      ]);
      
      const textResponse = response.response.text();
      if (textResponse) {
        return `✨ AI Study Summary\n\n${textResponse}`;
      }
    } catch (e) {
      console.log('AI summary skipped (timeout or error):', e);
    }
    
    return "✨ Study Summary (Local)\n\n• Document processed without AI.";
  },

  async extractKeywords(text) {
    if (!text) return [];
    const truncated = text.length > 1500 ? text.substring(0, 1500) : text;

    try {
      const prompt = `Extract 6 important keywords from this text. Return ONLY a comma-separated list:\n\n${truncated}`;
      
      const response = await Promise.race([
        model.generateContent(prompt),
        new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 10000))
      ]);
      
      const textResponse = response.response.text();
      if (textResponse) {
        return textResponse.split(',').map(s => s.trim().replace(/[^a-zA-Z0-9 ]/g, '')).filter(s => s).slice(0, 6);
      }
    } catch (e) {
      console.log('AI keywords skipped (timeout or error):', e);
    }
    
    return ['Study', 'Material', 'Notes'];
  },

  detectSubject(text) {
    const subjects = {
      'Science': ['science', 'physics', 'chemistry', 'biology', 'gravity', 'energy'],
      'History': ['history', 'king', 'war', 'emperor', 'century', 'battle'],
      'Technology': ['technology', 'computer', 'software', 'hardware', 'code'],
      'Literature': ['literature', 'poetry', 'novel', 'author', 'writer'],
      'Business': ['business', 'finance', 'economics', 'market', 'money']
    };
    
    let bestSubject = 'Custom';
    let maxMatches = 0;
    const lowerText = text.toLowerCase();
    
    for (const [subject, keywords] of Object.entries(subjects)) {
      let matches = 0;
      for (const kw of keywords) {
        if (lowerText.includes(kw)) matches++;
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        bestSubject = subject;
      }
    }
    return bestSubject;
  }
};
