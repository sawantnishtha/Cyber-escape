import { adminApi } from '../api/adminApi';
import { gameApi } from '../api/gameApi';
import { simulatorEngine } from './simulatorEngine.js';

export const adminService = {
  // Validate if transition is permitted (Admin has master override authority)
  canTransition(currentState, targetState) {
    return true; // Admin has full authority at any time
  },

  // Transition game state
  async setGameState(adminKey, newState, roundNumber = null) {
    const apiRes = await adminApi.setGameState(adminKey, newState, roundNumber || 1);

    // Always broadcast across local tabs via BroadcastChannel as well
    const simSession = simulatorEngine.setGameState(newState, roundNumber);
    return apiRes.data || simSession;
  },

  // Direct status update for an individual team
  async updateTeamStatus(teamId, status, roundNumber = null) {
    await gameApi.updateTeamStatus(teamId, status, roundNumber);

    // Always broadcast across local tabs and sync local state
    return simulatorEngine.updateTeamStatus(teamId, status, roundNumber);
  },

  // Direct status update for all teams (e.g. bring everyone into active/selected)
  async updateAllTeamsStatus(status, roundNumber = null) {
    // Sync with simulator
    return simulatorEngine.updateAllTeamsStatus(status, roundNumber);
  },

  // Confirm selection of teams advancing to the next round
  async confirmRoundSelections(adminKey, roundNumber, selectedTeamIds) {
    const apiRes = await adminApi.confirmRoundSelections(adminKey, roundNumber, selectedTeamIds);

    // Always sync simulator and broadcast
    const simRes = simulatorEngine.confirmRoundSelections(roundNumber, selectedTeamIds);
    return apiRes.data || simRes;
  },

  // Fetch all selection history across all rounds
  async getAllSelectionHistory() {
    const apiData = await adminApi.getAllSelectionHistory();
    if (apiData) return apiData;

    const state = simulatorEngine.readState();
    return state?.roundSelections || [];
  },

  // Declare final Winner and Runner-up
  async declareFinalWinners(adminKey, winnerId, runnerUpId) {
    await adminApi.declareFinalWinners(adminKey, winnerId, runnerUpId);
    return simulatorEngine.declareFinalWinners(winnerId, runnerUpId);
  },

  // Fetch audit logs
  async getAuditLogs() {
    const apiData = await adminApi.getAuditLogs();
    if (apiData) return apiData;

    const state = simulatorEngine.readState();
    return state?.auditLogs || [];
  },

  // Full Reset of Competition Event (Supabase + Local Simulator + Anti-cheat strikes)
  async resetEvent(adminKey = 'ADMIN-CYBER-2026') {
    // 1. Backend Reset via adminApi
    await adminApi.resetEvent(adminKey);

    // 2. Clear all local proctoring strikes in localStorage
    try {
      if (typeof window !== 'undefined' && window.localStorage) {
        Object.keys(localStorage).forEach((key) => {
          if (key.startsWith('cyber_escape_strikes_')) {
            localStorage.removeItem(key);
          }
        });
      }
    } catch (e) {
      // ignore
    }

    // 3. Reset Local Simulator & Broadcast across all tabs
    const simResult = simulatorEngine.resetSimulation();
    simulatorEngine.broadcast('EVENT_RESTARTED', { timestamp: new Date().toISOString() });
    simulatorEngine.broadcast('STATE_CHANGED', { state: 'LANDING', round: 1 });

    return simResult;
  },

  // Reset demo simulation (alias for resetEvent)
  async resetDemoGame() {
    return this.resetEvent();
  }
};
