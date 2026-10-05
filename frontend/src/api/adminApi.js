import { apiClient } from './apiClient';

/**
 * Admin operations API endpoints to communicate with backend
 */
export const adminApi = {
  /**
   * Transition game state via backend RPC admin_set_game_state
   */
  async setGameState(adminKey, newState, roundNumber = 1) {
    if (!apiClient.isConfigured()) {
      return { success: false, fallback: true };
    }
    const result = await apiClient.rpc('admin_set_game_state', {
      p_admin_key: adminKey,
      p_new_state: newState,
      p_new_round: roundNumber || 1
    });

    if (result.success && result.data) {
      return result.data;
    }
    return { success: false, error: result.error };
  },

  /**
   * Confirm round advancing teams via backend RPC admin_confirm_round_selections
   */
  async confirmRoundSelections(adminKey, roundNumber, selectedTeamIds) {
    if (!apiClient.isConfigured()) {
      return { success: false, fallback: true };
    }
    const result = await apiClient.rpc('admin_confirm_round_selections', {
      p_admin_key: adminKey,
      p_round_number: roundNumber,
      p_selected_team_ids: selectedTeamIds
    });

    if (result.success && result.data) {
      return result.data;
    }
    return { success: false, error: result.error };
  },

  /**
   * Full Event Reset via backend RPC admin_reset_event and table cleanup
   */
  async resetEvent(adminKey = 'ADMIN-CYBER-2026') {
    if (!apiClient.isConfigured()) {
      return { success: false, fallback: true };
    }

    // Call atomic RPC function
    await apiClient.rpc('admin_reset_event', { p_admin_key: adminKey });

    try {
      const dummyFilter = '00000000-0000-0000-0000-000000000000';

      // Reset game_session to initial LANDING state
      await apiClient
        .from('game_session')
        .update({
          current_state: 'LANDING',
          current_round: 1,
          round_timer_seconds: 300,
          timer_started_at: new Date().toISOString(),
          started_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .neq('id', dummyFilter);

      // Reset all teams to active and Round 1
      await apiClient
        .from('teams')
        .update({
          status: 'active',
          current_round: 1,
          updated_at: new Date().toISOString()
        })
        .neq('id', dummyFilter);

      // Clear round scores, unlocked words, submitted questions, selections, and final attempts
      await apiClient.from('round_results').delete().neq('team_id', dummyFilter);
      await apiClient.from('team_words').delete().neq('team_id', dummyFilter);
      await apiClient.from('team_questions').delete().neq('team_id', dummyFilter);
      await apiClient.from('round_selections').delete().neq('team_id', dummyFilter);
      await apiClient.from('final_attempts').delete().neq('team_id', dummyFilter);

      // Log action
      await apiClient.from('audit_logs').insert([
        {
          admin_id: 'admin',
          action: 'EVENT_RESTARTED',
          round_number: 1,
          metadata: { timestamp: new Date().toISOString() }
        }
      ]);

      return { success: true };
    } catch (err) {
      console.warn('[adminApi] resetEvent error:', err);
      return { success: false, error: err.message };
    }
  },

  /**
   * Fetch all selection history across all rounds
   */
  async getAllSelectionHistory() {
    if (!apiClient.isConfigured()) return null;
    try {
      const { data, error } = await apiClient
        .from('round_selections')
        .select('*, teams(team_name)')
        .order('round_number', { ascending: true });
      if (error) throw error;
      return data;
    } catch (err) {
      console.warn('[adminApi] getAllSelectionHistory error:', err);
      return null;
    }
  },

  /**
   * Declare final tournament winners
   */
  async declareFinalWinners(adminKey, winnerId, runnerUpId) {
    if (!apiClient.isConfigured()) return false;
    try {
      await apiClient.from('audit_logs').insert([
        {
          admin_id: 'admin',
          action: 'FINAL_WINNERS_DECLARED',
          metadata: { winner_id: winnerId, runner_up_id: runnerUpId }
        }
      ]);
      await apiClient
        .from('game_session')
        .update({ current_state: 'FINAL_RESULT' })
        .neq('id', '00000000-0000-0000-0000-000000000000');
      return true;
    } catch (err) {
      console.warn('[adminApi] declareFinalWinners error:', err);
      return false;
    }
  },

  /**
   * Fetch audit logs
   */
  async getAuditLogs() {
    if (!apiClient.isConfigured()) return null;
    try {
      const { data, error } = await apiClient
        .from('audit_logs')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);
      if (error) throw error;
      return data;
    } catch (err) {
      console.warn('[adminApi] getAuditLogs error:', err);
      return null;
    }
  }
};

export default adminApi;
