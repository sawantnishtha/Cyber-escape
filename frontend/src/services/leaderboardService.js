import { leaderboardApi } from '../api/leaderboardApi';
import { simulatorEngine } from './simulatorEngine';

export const leaderboardService = {
  async getLiveLeaderboard(currentRound = null) {
    const apiData = await leaderboardApi.fetchLeaderboardData();
    if (apiData && apiData.teams) {
      return this.aggregateLeaderboard(
        apiData.teams,
        apiData.results,
        apiData.finalAttempts,
        apiData.selections,
        currentRound
      );
    }

    const state = simulatorEngine.readState();
    if (!state) return [];

    const teams = state.teams;
    const results = Object.values(state.roundResults || {});
    const finalAttempts = state.finalAttempts || [];
    const selections = state.roundSelections || [];

    return this.aggregateLeaderboard(teams, results, finalAttempts, selections, currentRound);
  },

  aggregateLeaderboard(teams, results, finalAttempts, selections, currentRound) {
    const list = teams.map((team) => {
      // Find results for current round or aggregate
      const teamResults = results.filter((r) => r.team_id === team.id);
      
      const targetRoundResult = currentRound
        ? teamResults.find((r) => r.round_number === currentRound)
        : null;

      const totalScore = teamResults.reduce((acc, r) => acc + (r.score || 0), 0);
      const totalSolved = teamResults.reduce((acc, r) => acc + (r.questions_solved || 0), 0);
      const totalTime = teamResults.reduce((acc, r) => acc + Number(r.total_time_seconds || 0), 0);
      const totalHints = teamResults.reduce((acc, r) => acc + (r.hints_used || 0), 0);
      const totalAttempts = teamResults.reduce((acc, r) => acc + (r.attempts_count || 0), 0);
      const codeCompleted = targetRoundResult ? targetRoundResult.code_completed : teamResults.some((r) => r.code_completed);

      // Check final correct attempt timestamp
      const correctFinal = finalAttempts.find((fa) => fa.team_id === team.id && fa.is_correct);

      // Check selections history
      const teamSelections = selections.filter((s) => s.team_id === team.id);

      return {
        id: team.id,
        team_name: team.team_name,
        current_round: team.current_round,
        status: team.status,
        connected: Boolean(team.connected_at),
        score: targetRoundResult ? targetRoundResult.score : totalScore,
        questions_solved: targetRoundResult ? targetRoundResult.questions_solved : totalSolved,
        total_time_seconds: targetRoundResult ? Number(targetRoundResult.total_time_seconds || 0) : totalTime,
        hints_used: targetRoundResult ? targetRoundResult.hints_used : totalHints,
        attempts_count: targetRoundResult ? targetRoundResult.attempts_count : totalAttempts,
        code_completed: codeCompleted,
        final_submission_at: correctFinal ? correctFinal.submitted_at : null,
        selections: teamSelections
      };
    });

    // Objective sorting rules:
    // 1. If final completed, sort by final submission timestamp first!
    // 2. Higher questions_solved / score
    // 3. Code completed
    // 4. Lower total time
    // 5. Fewer hints
    list.sort((a, b) => {
      if (a.final_submission_at && b.final_submission_at) {
        return new Date(a.final_submission_at).getTime() - new Date(b.final_submission_at).getTime();
      }
      if (a.final_submission_at && !b.final_submission_at) return -1;
      if (!a.final_submission_at && b.final_submission_at) return 1;

      if (b.score !== a.score) return b.score - a.score;
      if (b.questions_solved !== a.questions_solved) return b.questions_solved - a.questions_solved;
      if (a.code_completed !== b.code_completed) return a.code_completed ? -1 : 1;
      if (a.total_time_seconds !== b.total_time_seconds) return a.total_time_seconds - b.total_time_seconds;
      if (a.hints_used !== b.hints_used) return a.hints_used - b.hints_used;
      return a.attempts_count - b.attempts_count;
    });

    // Assign rank
    return list.map((item, idx) => ({
      ...item,
      rank: idx + 1
    }));
  }
};
