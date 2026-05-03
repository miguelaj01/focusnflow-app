Selected Curated Questions — Team U30 (FocusNFlow)


Implementation Questions

1) Describe the exact order you implemented your three most complex mobile features and why that order reduced risk.

2) Which feature was reworked after user-flow testing, and what changed in code and UI behavior?

3) Explain one real synchronization bug you encountered between app state and backend/local data.


Architecture & Design Questions

4) How does your current navigation structure support maintainability and future feature additions?

5) Identify one Firebase Security Rule (using request.auth.uid or custom claims) that directly prevented a bad write or unauthorized read — show the rule and the blocked scenario.

6) Describe the trade-off between strict Firestore rule validation and iterative development speed in your project.


Testing and Reliability Questions

7) Show one failure case your first implementation missed (network, auth, null state, or lifecycle issue).

8) How did you redesign the UX response so users can recover without confusion?


Firebase Integration Questions

9) Walk through your Firestore collection hierarchy. Why did you choose subcollections over top-level collections for your primary relational data?

10) Show a Security Rule that uses request.auth.uid or custom claims to scope access. Explain what happens when an unauthenticated request hits that path.

11) Describe the full FCM token lifecycle — when it is requested, where it is stored in Firestore, how it is refreshed, and how a notification is delivered.

12) How does your app gracefully degrade when a Firestore listener fails or FCM delivery is delayed? Show the user-facing error state.


Reflection Questions

13) If you restarted this app tomorrow, what would you architect differently first?
