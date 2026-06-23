import { Router } from 'express';
import authRoutes from '../modules/auth/routes/auth.routes.js';
import eventsRoutes from '../modules/events/routes/events.routes.js';
import clubsRoutes from '../modules/clubs/routes/clubs.routes.js';
import studySessionsRoutes from '../modules/study-sessions/routes/study-sessions.routes.js';
import studySessionMembershipRoutes from '../modules/study-session-membership/routes/study-session-membership.routes.js';
import shopRoutes from '../modules/shop/routes/shop.routes.js';
import connectionsRoutes from '../modules/connections/routes/connections.routes.js';
import clubMessagesRoutes from '../modules/club-messages/routes/club-messages.routes.js';
import clubRequestsRoutes from '../modules/club-requests/routes/club-requests.routes.js';
import badgesRoutes from '../modules/badges/routes/badges.routes.js';
import volunteeringRoutes from '../modules/volunteering/routes/volunteering.routes.js';
import volunteeringOpportunitiesRoutes from '../modules/volunteering-opportunities/routes/volunteering-opportunities.routes.js';
import calendarRoutes from '../modules/calendar/routes/calendar.routes.js';
import notificationsRoutes from '../modules/notifications/routes/notifications.routes.js';
import gamificationRoutes from '../modules/gamification/routes/gamification.routes.js';
import recommendationsRoutes from '../modules/recommendations/routes/recommendations.routes.js';
import systemLogsRoutes from '../modules/system-logs/routes/system-logs.routes.js';
import studyPlansRoutes from '../modules/study-plans/routes/study-plans.routes.js';
import searchHistoryRoutes from '../modules/search-history/routes/search-history.routes.js';
import studentProfileDraftsRoutes from '../modules/student-profile-drafts/routes/student-profile-drafts.routes.js';
import studentProfilesRoutes from '../modules/student-profiles/routes/student-profiles.routes.js';
import eventReservationsRoutes from '../modules/event-reservations/routes/event-reservations.routes.js';
import eventFeedbackRoutes from '../modules/event-feedback/routes/event-feedback.routes.js';
import clubMembershipRoutes from '../modules/club-membership/routes/club-membership.routes.js';
import engagementMetricsRoutes from '../modules/engagement-metrics/routes/engagement-metrics.routes.js';
import studentsRoutes from '../modules/students/routes/students.routes.js';
import usersRoutes from '../modules/users/routes/users.routes.js';
import aiRoutes from '../modules/ai/routes/ai.routes.js';
import peerMessagesRoutes from '../modules/peer-messages/routes/peer-messages.routes.js';
import profilingRoutes from '../modules/profiling/routes/profiling.routes.js';
import deanRoutes from '../modules/dean/routes/dean.routes.js';
import adminRoutes from '../modules/admin/routes/admin.routes.js';
import { authenticateJwt } from '../shared/middleware/auth/authenticate-jwt.js';

const router = Router();

router.get('/health', (_req, res) => {
  res.json({ message: 'AAURA backend is running.' });
});

router.use('/ai', aiRoutes);

router.use('/auth', authRoutes);

router.use(authenticateJwt);
router.use('/events', eventsRoutes);
router.use('/clubs', clubsRoutes);
router.use('/club-requests', clubRequestsRoutes);
router.use('/study-sessions', studySessionsRoutes);
router.use('/study-session-membership', studySessionMembershipRoutes);
router.use('/shop', shopRoutes);
router.use('/connections', connectionsRoutes);
router.use('/peer-messages', peerMessagesRoutes);
router.use('/club-messages', clubMessagesRoutes);
router.use('/badges', badgesRoutes);
router.use('/volunteering', volunteeringRoutes);
router.use('/volunteering-opportunities', volunteeringOpportunitiesRoutes);
router.use('/calendar', calendarRoutes);
router.use('/notifications', notificationsRoutes);
router.use('/gamification', gamificationRoutes);
router.use('/recommendations', recommendationsRoutes);
router.use('/system-logs', systemLogsRoutes);
router.use('/study-plans', studyPlansRoutes);
router.use('/search-history', searchHistoryRoutes);
router.use('/student-profile-drafts', studentProfileDraftsRoutes);
router.use('/student-profiles', studentProfilesRoutes);
router.use('/event-reservations', eventReservationsRoutes);
router.use('/event-feedback', eventFeedbackRoutes);
router.use('/club-membership', clubMembershipRoutes);
router.use('/engagement-metrics', engagementMetricsRoutes);
router.use('/students', studentsRoutes);
router.use('/users', usersRoutes);
router.use('/dean', deanRoutes);
router.use('/admin', adminRoutes);
router.use('/profiling', profilingRoutes);

export default router;
