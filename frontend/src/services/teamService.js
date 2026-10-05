import { gameApi } from '../api/gameApi';
import { authApi } from '../api/authApi';
import { simulatorEngine } from './simulatorEngine';

export const teamService = {
  async getTeamDetails(teamId) {
    const apiTeam = await authApi.getTeamProfile(teamId);
    if (apiTeam) return apiTeam;

    const state = simulatorEngine.readState();
    return state?.teams.find((t) => t.id === teamId) || null;
  },

  async getTeamWords(teamId) {
    const apiWords = await gameApi.getTeamWords(teamId);
    if (apiWords) return apiWords;

    const state = simulatorEngine.readState();
    return state?.teamWords.filter((tw) => tw.team_id === teamId) || [];
  },

  async getTeamProgress(teamId, roundNumber) {
    const apiProgress = await gameApi.getTeamProgress(teamId, roundNumber);
    if (apiProgress) return apiProgress;

    const state = simulatorEngine.readState();
    if (!state) return { totalAttempts: 0, solvedCount: 0, solvedQuestionNumbers: [] };

    const teamQ = state.teamQuestions.filter(
      (tq) => tq.team_id === teamId && tq.round_number === roundNumber
    );
    const correctQ = teamQ.filter((tq) => tq.is_correct);
    return {
      totalAttempts: teamQ.length,
      solvedCount: correctQ.length,
      solvedQuestionNumbers: correctQ.map((c) => c.question_number)
    };
  },

  async getTeamSelections(teamId) {
    const apiSelections = await gameApi.getTeamSelections(teamId);
    if (apiSelections) return apiSelections;

    const state = simulatorEngine.readState();
    return state?.roundSelections.filter((rs) => rs.team_id === teamId) || [];
  }
};
