import * as pdfjsLib from 'pdfjs-dist';

// Use local copy of the worker served from /public — no CDN dependency
pdfjsLib.GlobalWorkerOptions.workerSrc = '/pdf.worker.min.mjs';

export const pdfService = {
  async extractText(file) {
    try {
      console.log("Starting PDF extraction...");
      const arrayBuffer = await file.arrayBuffer();
      const data = new Uint8Array(arrayBuffer);
      
      console.log("Parsing PDF document...");
      const pdf = await pdfjsLib.getDocument({ data }).promise;
      const numPages = pdf.numPages;
      let fullText = '';

      console.log(`Extracting text from ${numPages} pages...`);
      for (let i = 1; i <= numPages; i++) {
        const page = await pdf.getPage(i);
        const textContent = await page.getTextContent();
        const pageText = textContent.items.map(item => item.str).join(' ');
        fullText += pageText + '\\n\\n';
      }

      console.log("PDF extraction complete.");
      return {
        text: fullText,
        pageCount: numPages
      };
    } catch (e) {
      console.error('Error extracting PDF text:', e);
      throw e;
    }
  },

  formatBytes(bytes, decimals = 2) {
    if (!+bytes) return '0 Bytes';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
  }
};
