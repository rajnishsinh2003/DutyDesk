import * as admin from 'firebase-admin';

admin.initializeApp();

export { chatAsk } from './chatAsk';
export {
  onChatbotDocumentCreated,
  onChatbotFaqWritten,
  reindexDocument,
  deleteDocument,
} from './processDocument';
export {
  submitFeedback,
  adminReviewMessage,
  resolveUnanswered,
  flagSession,
  logAdminAudit,
} from './admin';
export { retentionCleanup } from './cleanup';
