import React, { useState, useEffect, useMemo } from 'react';
import {
  Terminal,
  Play,
  Square,
  Users,
  Clock,
  CheckSquare,
  Activity,
  AlertTriangle,
  RotateCcw,
  Sparkles,
  Trophy,
  Search,
  Check,
  Radio
} from 'lucide-react';
import { soundEffects } from '../../utils/soundEffects';
import { adminService } from '../../services/adminService';
import { leaderboardService } from '../../services/leaderboardService';
import { ConfirmModal } from '../../components/ConfirmModal';
import { GAME_STATES } from '../../constants/gameConfig';

// Master list of all available game screens for Global Dropdown
const GLOBAL_SCREENS = [
  { value: GAME_STATES.LANDING, label: 'RULES / LOBBY (RESET)', round: 1 },
  { value: GAME_STATES.R1_WAITING, label: 'ROUND 1 WAITING ROOM', round: 1 },
  { value: GAME_STATES.R1_ACTIVE, label: 'ROUND 1 ACTIVE (MCQs)', round: 1 },
  { value: GAME_STATES.R1_RESULT, label: 'ROUND 1 RESULTS & EVALUATION', round: 1 },

  { value: GAME_STATES.R2_WAITING, label: 'ROUND 2 WAITING ROOM', round: 2 },
  { value: GAME_STATES.R2_ACTIVE, label: 'ROUND 2 ACTIVE (CROSSWORDS)', round: 2 },
  { value: GAME_STATES.R2_RESULT, label: 'ROUND 2 RESULTS & EVALUATION', round: 2 },

  { value: GAME_STATES.R3_WAITING, label: 'ROUND 3 WAITING ROOM', round: 3 },
  { value: GAME_STATES.R3_ACTIVE, label: 'ROUND 3 ACTIVE (BINARY MATRIX)', round: 3 },
  { value: GAME_STATES.R3_RESULT, label: 'ROUND 3 RESULTS & EVALUATION', round: 3 },

  { value: GAME_STATES.R4_WAITING, label: 'ROUND 4 WAITING ROOM', round: 4 },
  { value: GAME_STATES.R4_ACTIVE, label: 'ROUND 4 ACTIVE (SYSTEM OVERRIDE)', round: 4 },
  { value: GAME_STATES.R4_RESULT, label: 'ROUND 4 RESULTS & EVALUATION', round: 4 },

  { value: GAME_STATES.FINAL_WAITING, label: 'FINAL WAITING ROOM', round: 4 },
  { value: GAME_STATES.FINAL_RIDDLE, label: 'FINAL RIDDLE PROTOCOL', round: 4 },
  { value: GAME_STATES.FINAL_RESULT, label: 'OFFICIAL WINNERS PODIUM', round: 4 }
];

export function AdminDashboard({ admin, gameSession, onResetDemo }) {
  // Navigation Tabs: 'controls' | 'r1_manage' | 'r2_manage' | 'r3_manage' | 'r4_manage' | 'submissions'
  const [activeTab, setActiveTab] = useState('controls');

  const [leaderboard, setLeaderboard] = useState([]);
  const [selectedTeamsMap, setSelectedTeamsMap] = useState({});
  const [selectionHistory, setSelectionHistory] = useState([]);
  const [auditLogs, setAuditLogs] = useState([]);

  const currentState = gameSession?.current_state || GAME_STATES.LANDING;
  const currentRound = gameSession?.current_round || 1;

  // Search query for team monitor
  const [teamSearchQuery, setTeamSearchQuery] = useState('');

  // Confirmation modal config
  const [confirmModalConfig, setConfirmModalConfig] = useState(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [statusNotice, setStatusNotice] = useState('SYSTEM INITIALIZED. READY FOR COMMANDS.');

  // Final winners pickers
  const [selectedWinnerId, setSelectedWinnerId] = useState('');
  const [selectedRunnerUpId, setSelectedRunnerUpId] = useState('');

  // Fetch live dashboard telemetry
  const fetchData = async () => {
    try {
      const lb = await leaderboardService.getLiveLeaderboard(currentRound);
      setLeaderboard(lb);

      const history = await adminService.getAllSelectionHistory();
      setSelectionHistory(history);

      const logs = await adminService.getAuditLogs();
      setAuditLogs(logs);
    } catch (err) {
      console.error('Error fetching admin telemetry:', err);
    }
  };

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 1500);
    return () => clearInterval(interval);
  }, [currentRound, currentState]);

  const showConsoleNotice = (msg) => {
    setStatusNotice(`> ${msg}`);
  };

  // State Transition Action with instant broadcast
  const handleTransitionState = (targetState, targetRound, actionLabel, isDanger = false) => {
    soundEffects.playClick();
    setConfirmModalConfig({
      title: `${actionLabel.toUpperCase()}?`,
      message: `Broadcast game state transition to: ${targetState} (Round ${targetRound})? All synchronized team screens will update instantaneously.`,
      danger: isDanger,
      onConfirm: async () => {
        setIsProcessing(true);
        try {
          if (targetState === GAME_STATES.LANDING || targetState === GAME_STATES.R1_WAITING) {
            await adminService.updateAllTeamsStatus('active', targetRound);
          }

          await adminService.setGameState('ADMIN-CYBER-2026', targetState, targetRound);
          soundEffects.playAccessGranted();
          showConsoleNotice(`BROADCAST DISPATCHED: ${actionLabel.toUpperCase()} (${targetState})`);
          fetchData();
        } catch (err) {
          alert('Failed to update state: ' + err.message);
        } finally {
          setIsProcessing(false);
          setConfirmModalConfig(null);
        }
      }
    });
  };

  // Global Dropdown Screen Change
  const handleGlobalScreenChange = (newScreenVal) => {
    const screenItem = GLOBAL_SCREENS.find((s) => s.value === newScreenVal);
    if (!screenItem) return;
    handleTransitionState(
      screenItem.value,
      screenItem.round,
      `Switch to ${screenItem.label}`,
      screenItem.value === GAME_STATES.LANDING
    );
  };

  // Toggle selection for a team
  const toggleTeamSelection = (teamId) => {
    soundEffects.playClick();
    setSelectedTeamsMap((prev) => ({
      ...prev,
      [teamId]: !prev[teamId]
    }));
  };

  // Bulk selection helper
  const handleBulkSelect = (count = null) => {
    soundEffects.playClick();
    const newMap = {};
    const sorted = [...leaderboard].sort((a, b) => (a.rank || 99) - (b.rank || 99));

    if (count === null) {
      setSelectedTeamsMap({});
      return;
    }

    if (count === 'ALL') {
      sorted.forEach((t) => {
        newMap[t.id] = true;
      });
    } else {
      sorted.slice(0, count).forEach((t) => {
        newMap[t.id] = true;
      });
    }
    setSelectedTeamsMap(newMap);
  };

  // Direct team status toggle
  const handleTeamStatusChange = async (teamId, newStatus) => {
    soundEffects.playClick();
    try {
      await adminService.updateTeamStatus(teamId, newStatus, currentRound);
      soundEffects.playKeyUnlocked();
      showConsoleNotice(`TEAM ID ${teamId.slice(0, 8)} STATUS SET TO: ${newStatus.toUpperCase()}`);
      fetchData();
    } catch (err) {
      alert('Failed to update team: ' + err.message);
    }
  };

  // Confirm qualification for any round (reveals results & secret words to selected teams)
  const handleConfirmRoundQualification = (roundNumber, autoAdvance = false) => {
    soundEffects.playClick();
    const selectedIds = Object.keys(selectedTeamsMap).filter((id) => selectedTeamsMap[id]);

    if (selectedIds.length === 0) {
      alert('Please check at least 1 team to advance.');
      return;
    }

    setConfirmModalConfig({
      title: `CONFIRM ROUND ${roundNumber} QUALIFICATIONS?`,
      message: `You have selected ${selectedIds.length} team(s) to advance. Non-selected teams will be marked as Not Selected / Eliminated.\n\nQualified teams will immediately reveal their Secret Word on their screen. Proceed?`,
      danger: true,
      onConfirm: async () => {
        setIsProcessing(true);
        try {
          // 1. Save round selections to database and update team statuses
          await adminService.confirmRoundSelections('ADMIN-CYBER-2026', roundNumber, selectedIds);

          // 2. Set game state to the corresponding RESULT state so teams see their Qualified + Secret Word vs Not Selected screen
          let resultState = GAME_STATES.R1_RESULT;
          if (roundNumber === 1) resultState = GAME_STATES.R1_RESULT;
          else if (roundNumber === 2) resultState = GAME_STATES.R2_RESULT;
          else if (roundNumber === 3) resultState = GAME_STATES.R3_RESULT;
          else if (roundNumber === 4) resultState = GAME_STATES.R4_RESULT;

          if (autoAdvance) {
            let nextState = GAME_STATES.R2_WAITING;
            let nextRound = 2;
            if (roundNumber === 1) { nextState = GAME_STATES.R2_WAITING; nextRound = 2; }
            else if (roundNumber === 2) { nextState = GAME_STATES.R3_WAITING; nextRound = 3; }
            else if (roundNumber === 3) { nextState = GAME_STATES.R4_WAITING; nextRound = 4; }
            else if (roundNumber === 4) { nextState = GAME_STATES.FINAL_RIDDLE; nextRound = 4; }
            await adminService.setGameState('ADMIN-CYBER-2026', nextState, nextRound);
          } else {
            await adminService.setGameState('ADMIN-CYBER-2026', resultState, roundNumber);
          }

          soundEffects.playAccessGranted();
          showConsoleNotice(`ROUND ${roundNumber} SELECTION CONFIRMED! Results & secret words published.`);
          setSelectedTeamsMap({});
          fetchData();
        } catch (err) {
          alert('Confirmation failed: ' + err.message);
        } finally {
          setIsProcessing(false);
          setConfirmModalConfig(null);
        }
      }
    });
  };

  // Declare Final Winners and broadcast podium
  const handleDeclareFinalWinners = () => {
    soundEffects.playClick();
    if (!selectedWinnerId || !selectedRunnerUpId) {
      alert('Please choose both Champion (Winner) and Runner-up.');
      return;
    }
    if (selectedWinnerId === selectedRunnerUpId) {
      alert('Champion and Runner-up cannot be the same team.');
      return;
    }

    const winner = leaderboard.find((t) => t.id === selectedWinnerId);
    const runnerUp = leaderboard.find((t) => t.id === selectedRunnerUpId);

    setConfirmModalConfig({
      title: 'DECLARE WINNERS PODIUM',
      message: `Champion: ${winner?.team_name}\nRunner-up: ${runnerUp?.team_name}\n\nPublish official champion podium to all screens?`,
      danger: false,
      onConfirm: async () => {
        setIsProcessing(true);
        try {
          await adminService.declareFinalWinners('ADMIN-CYBER-2026', selectedWinnerId, selectedRunnerUpId, winner?.team_name, runnerUp?.team_name);
          soundEffects.playKeyUnlocked();
          showConsoleNotice(`FINAL PODIUM PUBLISHED // WINNER: ${winner?.team_name}, RUNNER-UP: ${runnerUp?.team_name}`);
          fetchData();
        } catch (err) {
          alert('Failed to declare winners: ' + err.message);
        } finally {
          setIsProcessing(false);
          setConfirmModalConfig(null);
        }
      }
    });
  };

  // Dedicated Emergency Restart Event handler
  const handleRestartEvent = () => {
    soundEffects.playClick();
    setConfirmModalConfig({
      title: 'RESTART ENTIRE EVENT?',
      message: 'This will reset all team states to Active/Round 1, return the game session to the Lobby, clear all scores, words, and submissions, and reset all proctoring strikes. Proceed?',
      danger: true,
      onConfirm: async () => {
        setIsProcessing(true);
        try {
          await adminService.resetEvent('ADMIN-CYBER-2026');
          if (onResetDemo) {
            await onResetDemo();
          }
          setSelectedTeamsMap({});
          await fetchData();
          soundEffects.playAccessGranted();
          showConsoleNotice('EVENT RESTARTED // INITIAL DEFAULT STATE RESTORED');
        } catch (err) {
          alert('Failed to restart event: ' + err.message);
        } finally {
          setIsProcessing(false);
          setConfirmModalConfig(null);
        }
      }
    });
  };

  // Dedicated Emergency End Event handler
  const handleEndEvent = () => {
    soundEffects.playClick();
    
    // Auto-resolve winner and runner-up from leaderboard if not manually chosen
    const sorted = [...leaderboard].sort((a, b) => (a.rank || 99) - (b.rank || 99));
    const defaultWinner = sorted[0];
    const defaultRunnerUp = sorted[1];

    const winnerId = selectedWinnerId || defaultWinner?.id;
    const runnerUpId = selectedRunnerUpId || defaultRunnerUp?.id;

    const winnerName = leaderboard.find((t) => t.id === winnerId)?.team_name || defaultWinner?.team_name || 'TEAM ALPHA';
    const runnerUpName = leaderboard.find((t) => t.id === runnerUpId)?.team_name || defaultRunnerUp?.team_name || 'TEAM BETA';

    setConfirmModalConfig({
      title: 'END TOURNAMENT & DECLARE CHAMPIONS?',
      message: `Are you sure you want to conclude the event?\n\n• Champion (1st): ${winnerName}\n• Runner-up (2nd): ${runnerUpName}\n\nThis will terminate active challenges and broadcast the Official Winners Podium to all screens.`,
      danger: true,
      onConfirm: async () => {
        setIsProcessing(true);
        try {
          if (winnerId && runnerUpId) {
            await adminService.declareFinalWinners('ADMIN-CYBER-2026', winnerId, runnerUpId, winnerName, runnerUpName);
          } else {
            await adminService.setGameState('ADMIN-CYBER-2026', GAME_STATES.FINAL_RESULT, 4);
          }
          soundEffects.playAccessGranted();
          showConsoleNotice(`TOURNAMENT CONCLUDED // CHAMPION: ${winnerName}, RUNNER-UP: ${runnerUpName}`);
          fetchData();
        } catch (err) {
          alert('Failed to end event: ' + err.message);
        } finally {
          setIsProcessing(false);
          setConfirmModalConfig(null);
        }
      }
    });
  };

  // Filtered leaderboard
  const filteredLeaderboard = useMemo(() => {
    return leaderboard.filter((t) => {
      if (!teamSearchQuery.trim()) return true;
      const q = teamSearchQuery.toLowerCase();
      return (
        t.team_name.toLowerCase().includes(q) ||
        (t.id && t.id.toLowerCase().includes(q))
      );
    });
  }, [leaderboard, teamSearchQuery]);

  const connectedCount = leaderboard.filter((t) => t.connected).length;

  const currentRoundTitle = useMemo(() => {
    if (currentRound === 1) return 'ROUND 01: THE FIRST BREACH';
    if (currentRound === 2) return 'ROUND 02: GRIDLOCK PROTOCOL';
    if (currentRound === 3) return 'ROUND 03: BINARY CONVERGENCE';
    if (currentRound === 4) return 'ROUND 04: SYSTEM OVERRIDE';
    return 'CYBER ESCAPE';
  }, [currentRound]);

  // Simple, clean, high-legibility typography for Admin Operations
  const adminSans = { fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" };
  const adminMono = { fontFamily: "'Fira Code', 'Roboto Mono', Consolas, monospace", fontVariantNumeric: 'tabular-nums' };

  return (
    <div
      className="admin-dashboard-container"
      style={{
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        padding: '1.2rem 2rem',
        maxWidth: '1440px',
        margin: '0 auto',
        width: '100%',
        color: '#f1f5f9',
        ...adminSans
      }}
    >
      <div className="cyber-bg" />
      <div className="cyber-bg-radial" />

      {/* ============================================================== */}
      {/* 1. TOP MODULAR STATUS BAR (4 BOXES - CYBER ESCAPE THEMED) */}
      {/* ============================================================== */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: '1rem',
          marginBottom: '1rem',
          position: 'relative',
          zIndex: 1
        }}
      >
        {/* BOX 1: CURRENT MISSION */}
        <div
          style={{
            background: 'rgba(10, 17, 34, 0.88)',
            border: '1px solid rgba(0, 243, 255, 0.28)',
            borderRadius: '6px',
            padding: '0.9rem 1.2rem',
            backdropFilter: 'blur(12px)',
            boxShadow: '0 4px 20px rgba(0, 0, 0, 0.35)'
          }}
        >
          <div
            style={{
              fontSize: '0.72rem',
              color: 'var(--neon-cyan)',
              ...adminSans,
              textTransform: 'uppercase',
              letterSpacing: '0.05em',
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              marginBottom: '0.3rem',
              fontWeight: '700'
            }}
          >
            <Activity size={13} color="var(--neon-cyan)" /> CURRENT ROUND / MISSION
          </div>
          <div
            style={{
              fontSize: '1.15rem',
              fontWeight: '700',
              color: '#ffffff',
              letterSpacing: '0.02em',
              whiteSpace: 'nowrap',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              ...adminSans
            }}
          >
            {currentRoundTitle}
          </div>
        </div>

        {/* BOX 2: GLOBAL LIVE SCREEN DROPDOWN */}
        <div
          style={{
            background: 'rgba(10, 17, 34, 0.88)',
            border: '1px solid rgba(255, 183, 0, 0.35)',
            borderRadius: '6px',
            padding: '0.9rem 1.2rem',
            backdropFilter: 'blur(12px)',
            boxShadow: '0 4px 20px rgba(0, 0, 0, 0.35)'
          }}
        >
          <div
            style={{
              fontSize: '0.72rem',
              color: 'var(--neon-amber)',
              ...adminSans,
              textTransform: 'uppercase',
              letterSpacing: '0.05em',
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              marginBottom: '0.3rem',
              fontWeight: '700'
            }}
          >
            <Radio size={13} color="var(--neon-amber)" /> GLOBAL LIVE SCREEN
          </div>
          <div>
            <select
              value={currentState}
              onChange={(e) => handleGlobalScreenChange(e.target.value)}
              style={{
                width: '100%',
                background: '#070c1a',
                border: '1px solid rgba(255, 183, 0, 0.45)',
                borderRadius: '4px',
                color: 'var(--neon-amber)',
                ...adminSans,
                fontSize: '0.84rem',
                fontWeight: '600',
                padding: '0.4rem 0.6rem',
                cursor: 'pointer'
              }}
            >
              {GLOBAL_SCREENS.map((screen) => (
                <option key={screen.value} value={screen.value}>
                  {screen.label}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* BOX 3: CONNECTED TEAMS */}
        <div
          style={{
            background: 'rgba(10, 17, 34, 0.88)',
            border: '1px solid rgba(0, 243, 255, 0.28)',
            borderRadius: '6px',
            padding: '0.9rem 1.2rem',
            backdropFilter: 'blur(12px)',
            boxShadow: '0 4px 20px rgba(0, 0, 0, 0.35)'
          }}
        >
          <div
            style={{
              fontSize: '0.72rem',
              color: 'var(--neon-cyan)',
              ...adminSans,
              textTransform: 'uppercase',
              letterSpacing: '0.05em',
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              marginBottom: '0.3rem',
              fontWeight: '700'
            }}
          >
            <Users size={13} color="var(--neon-cyan)" /> CONNECTED TEAMS
          </div>
          <div
            style={{
              fontSize: '1.25rem',
              fontWeight: '700',
              color: '#ffffff',
              ...adminSans,
              fontVariantNumeric: 'tabular-nums'
            }}
          >
            {connectedCount} TEAMS
          </div>
        </div>

        {/* BOX 4: EVENT STATUS */}
        <div
          style={{
            background: 'rgba(10, 17, 34, 0.88)',
            border: '1px solid rgba(0, 255, 136, 0.3)',
            borderRadius: '6px',
            padding: '0.9rem 1.2rem',
            backdropFilter: 'blur(12px)',
            boxShadow: '0 4px 20px rgba(0, 0, 0, 0.35)'
          }}
        >
          <div
            style={{
              fontSize: '0.72rem',
              color: 'var(--neon-green)',
              ...adminSans,
              textTransform: 'uppercase',
              letterSpacing: '0.05em',
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              marginBottom: '0.3rem',
              fontWeight: '700'
            }}
          >
            <Activity size={13} color="var(--neon-green)" /> EVENT STATUS
          </div>
          <div
            style={{
              fontSize: '1.25rem',
              fontWeight: '700',
              color: 'var(--neon-green)',
              ...adminSans,
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem'
            }}
          >
            <span className="pulse-dot" style={{ background: 'var(--neon-green)' }} /> ONLINE
          </div>
        </div>
      </div>

      {/* ============================================================== */}
      {/* 2. SYSTEM CONSOLE TICKER BAR */}
      {/* ============================================================== */}
      <div
        style={{
          background: 'rgba(7, 12, 26, 0.92)',
          border: '1px solid rgba(0, 243, 255, 0.22)',
          borderRadius: '4px',
          padding: '0.6rem 1rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '1.2rem',
          fontSize: '0.8rem',
          position: 'relative',
          zIndex: 1
        }}
      >
        <div style={{ color: 'var(--neon-cyan)', display: 'flex', alignItems: 'center', gap: '0.5rem', ...adminMono }}>
          <Terminal size={14} color="var(--neon-cyan)" />
          <span>{statusNotice}</span>
        </div>

        <div
          style={{
            border: '1px solid var(--neon-amber)',
            borderRadius: '3px',
            padding: '0.2rem 0.6rem',
            color: 'var(--neon-amber)',
            fontSize: '0.7rem',
            fontWeight: '700',
            letterSpacing: '0.05em',
            ...adminSans
          }}
        >
          REALTIME BROADCAST ARMED
        </div>
      </div>

      {/* ============================================================== */}
      {/* 3. NAVIGATION TABS */}
      {/* ============================================================== */}
      <div
        style={{
          display: 'flex',
          gap: '0.5rem',
          borderBottom: '1px solid rgba(0, 243, 255, 0.2)',
          marginBottom: '1.5rem',
          paddingBottom: '0.3rem',
          flexWrap: 'wrap',
          position: 'relative',
          zIndex: 1
        }}
      >
        {[
          { key: 'controls', label: 'LIVE EVENT CONTROLS' },
          { key: 'r1_manage', label: 'ROUND 1 SELECTION (THE FIRST BREACH)' },
          { key: 'r2_manage', label: 'ROUND 2 SELECTION (GRIDLOCK PROTOCOL)' },
          { key: 'r3_manage', label: 'ROUND 3 SELECTION (BINARY CONVERGENCE)' },
          { key: 'r4_manage', label: 'ROUND 4 & FINAL RIDDLE' },
          { key: 'submissions', label: 'ROUND SUBMISSIONS & TIMELINES' }
        ].map((tab) => {
          const isActive = activeTab === tab.key;
          return (
            <button
              key={tab.key}
              onClick={() => {
                soundEffects.playClick();
                setActiveTab(tab.key);
              }}
              style={{
                background: isActive ? 'var(--neon-cyan)' : 'transparent',
                color: isActive ? '#020814' : '#94a3b8',
                border: 'none',
                padding: '0.55rem 1.1rem',
                fontSize: '0.8rem',
                fontWeight: '700',
                ...adminSans,
                letterSpacing: '0.02em',
                borderRadius: '4px 4px 0 0',
                cursor: 'pointer',
                transition: 'all 0.15s ease'
              }}
            >
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* ============================================================== */}
      {/* TAB 1: LIVE EVENT CONTROLS (CARDS + EMERGENCY + LIVE MONITOR) */}
      {/* ============================================================== */}
      {activeTab === 'controls' && (
        <div style={{ position: 'relative', zIndex: 1 }}>
          {/* Mission / Round Cards Grid */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(310px, 1fr))',
              gap: '1.2rem',
              marginBottom: '1.8rem'
            }}
          >
            {/* CARD 1: ROUND 1 */}
            <div
              style={{
                background: 'rgba(10, 17, 34, 0.85)',
                border: '1px solid rgba(0, 243, 255, 0.28)',
                borderRadius: '8px',
                padding: '1.4rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.8rem',
                backdropFilter: 'blur(12px)'
              }}
            >
              <div>
                <h2
                  style={{
                    fontSize: '1.1rem',
                    fontWeight: '700',
                    color: 'var(--neon-cyan)',
                    letterSpacing: '0.02em',
                    margin: 0,
                    ...adminSans
                  }}
                >
                  ROUND 1: THE FIRST BREACH
                </h2>
                <div style={{ fontSize: '0.75rem', color: '#94a3b8', ...adminSans, marginTop: '0.2rem', fontWeight: '500' }}>
                  MCQ FIREWALL INTRUSION PROTOCOL
                </div>
              </div>

              {/* Action Buttons */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem', marginTop: '0.4rem' }}>
                <button
                  onClick={() => handleTransitionState(GAME_STATES.R1_ACTIVE, 1, 'Start Round 1')}
                  style={{
                    background: 'linear-gradient(135deg, #ffb700, #f59e0b)',
                    color: '#000',
                    fontWeight: '700',
                    fontSize: '0.88rem',
                    ...adminSans,
                    padding: '0.75rem 1rem',
                    border: 'none',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer',
                    boxShadow: '0 0 16px rgba(255, 183, 0, 0.35)'
                  }}
                >
                  <Play size={16} fill="#000" /> START ROUND 1
                </button>

                <button
                  onClick={() => handleTransitionState(GAME_STATES.R1_WAITING, 1, 'Open Round 1 Waiting Room')}
                  style={{
                    background: 'rgba(13, 22, 44, 0.85)',
                    border: '1px solid rgba(0, 243, 255, 0.25)',
                    color: '#e2e8f0',
                    fontSize: '0.82rem',
                    ...adminSans,
                    fontWeight: '600',
                    padding: '0.65rem 1rem',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer'
                  }}
                >
                  <Clock size={15} color="var(--neon-cyan)" /> WAITING ROOM
                </button>

                <button
                  onClick={() => handleTransitionState(GAME_STATES.R1_RESULT, 1, 'Publish Round 1 Results', true)}
                  style={{
                    background: 'rgba(13, 22, 44, 0.85)',
                    border: '1px solid rgba(0, 255, 136, 0.28)',
                    color: 'var(--neon-green)',
                    fontSize: '0.82rem',
                    ...adminSans,
                    fontWeight: '600',
                    padding: '0.65rem 1rem',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer'
                  }}
                >
                  <CheckSquare size={15} color="var(--neon-green)" /> PUBLISH ROUND 1 RESULTS
                </button>
              </div>
            </div>

            {/* CARD 2: ROUND 2 */}
            <div
              style={{
                background: 'rgba(10, 17, 34, 0.85)',
                border: '1px solid rgba(0, 243, 255, 0.28)',
                borderRadius: '8px',
                padding: '1.4rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.8rem',
                backdropFilter: 'blur(12px)'
              }}
            >
              <div>
                <h2
                  style={{
                    fontSize: '1.1rem',
                    fontWeight: '700',
                    color: 'var(--neon-cyan)',
                    letterSpacing: '0.02em',
                    margin: 0,
                    ...adminSans
                  }}
                >
                  ROUND 2: GRIDLOCK PROTOCOL
                </h2>
                <div style={{ fontSize: '0.75rem', color: '#94a3b8', ...adminSans, marginTop: '0.2rem', fontWeight: '500' }}>
                  TECHNICAL CRYPTOGRAPHIC CROSSWORDS
                </div>
              </div>

              {/* Action Buttons */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem', marginTop: '0.4rem' }}>
                <button
                  onClick={() => handleTransitionState(GAME_STATES.R2_ACTIVE, 2, 'Start Round 2')}
                  style={{
                    background: 'linear-gradient(135deg, #ffb700, #f59e0b)',
                    color: '#000',
                    fontWeight: '700',
                    fontSize: '0.88rem',
                    ...adminSans,
                    padding: '0.75rem 1rem',
                    border: 'none',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer',
                    boxShadow: '0 0 16px rgba(255, 183, 0, 0.35)'
                  }}
                >
                  <Play size={16} fill="#000" /> START ROUND 2
                </button>

                <button
                  onClick={() => handleTransitionState(GAME_STATES.R2_WAITING, 2, 'Open Round 2 Waiting Room')}
                  style={{
                    background: 'rgba(13, 22, 44, 0.85)',
                    border: '1px solid rgba(0, 243, 255, 0.25)',
                    color: '#e2e8f0',
                    fontSize: '0.82rem',
                    ...adminSans,
                    fontWeight: '600',
                    padding: '0.65rem 1rem',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer'
                  }}
                >
                  <Clock size={15} color="var(--neon-cyan)" /> WAITING ROOM
                </button>

                <button
                  onClick={() => handleTransitionState(GAME_STATES.R2_RESULT, 2, 'Publish Round 2 Results', true)}
                  style={{
                    background: 'rgba(13, 22, 44, 0.85)',
                    border: '1px solid rgba(0, 255, 136, 0.28)',
                    color: 'var(--neon-green)',
                    fontSize: '0.82rem',
                    ...adminSans,
                    fontWeight: '600',
                    padding: '0.65rem 1rem',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer'
                  }}
                >
                  <CheckSquare size={15} color="var(--neon-green)" /> PUBLISH ROUND 2 RESULTS
                </button>
              </div>
            </div>

            {/* CARD 3: ROUND 3 */}
            <div
              style={{
                background: 'rgba(10, 17, 34, 0.85)',
                border: '1px solid rgba(0, 243, 255, 0.28)',
                borderRadius: '8px',
                padding: '1.4rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.8rem',
                backdropFilter: 'blur(12px)'
              }}
            >
              <div>
                <h2
                  style={{
                    fontSize: '1.1rem',
                    fontWeight: '700',
                    color: 'var(--neon-cyan)',
                    letterSpacing: '0.02em',
                    margin: 0,
                    ...adminSans
                  }}
                >
                  ROUND 3: BINARY CONVERGENCE
                </h2>
                <div style={{ fontSize: '0.75rem', color: '#94a3b8', ...adminSans, marginTop: '0.2rem', fontWeight: '500' }}>
                  ASCII DECRYPTION MATRIX STREAM
                </div>
              </div>

              {/* Action Buttons */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem', marginTop: '0.4rem' }}>
                <button
                  onClick={() => handleTransitionState(GAME_STATES.R3_ACTIVE, 3, 'Start Round 3')}
                  style={{
                    background: 'linear-gradient(135deg, #ffb700, #f59e0b)',
                    color: '#000',
                    fontWeight: '700',
                    fontSize: '0.88rem',
                    ...adminSans,
                    padding: '0.75rem 1rem',
                    border: 'none',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer',
                    boxShadow: '0 0 16px rgba(255, 183, 0, 0.35)'
                  }}
                >
                  <Play size={16} fill="#000" /> START ROUND 3
                </button>

                <button
                  onClick={() => handleTransitionState(GAME_STATES.R3_WAITING, 3, 'Open Round 3 Waiting Room')}
                  style={{
                    background: 'rgba(13, 22, 44, 0.85)',
                    border: '1px solid rgba(0, 243, 255, 0.25)',
                    color: '#e2e8f0',
                    fontSize: '0.82rem',
                    ...adminSans,
                    fontWeight: '600',
                    padding: '0.65rem 1rem',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer'
                  }}
                >
                  <Clock size={15} color="var(--neon-cyan)" /> WAITING ROOM
                </button>

                <button
                  onClick={() => handleTransitionState(GAME_STATES.R3_RESULT, 3, 'Publish Round 3 Results', true)}
                  style={{
                    background: 'rgba(13, 22, 44, 0.85)',
                    border: '1px solid rgba(0, 255, 136, 0.28)',
                    color: 'var(--neon-green)',
                    fontSize: '0.82rem',
                    ...adminSans,
                    fontWeight: '600',
                    padding: '0.65rem 1rem',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer'
                  }}
                >
                  <CheckSquare size={15} color="var(--neon-green)" /> PUBLISH ROUND 3 RESULTS
                </button>
              </div>
            </div>

            {/* CARD 4: ROUND 4 & FINAL RIDDLE */}
            <div
              style={{
                background: 'rgba(10, 17, 34, 0.85)',
                border: '1px solid rgba(0, 243, 255, 0.28)',
                borderRadius: '8px',
                padding: '1.4rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.8rem',
                backdropFilter: 'blur(12px)'
              }}
            >
              <div>
                <h2
                  style={{
                    fontSize: '1.1rem',
                    fontWeight: '700',
                    color: 'var(--neon-cyan)',
                    letterSpacing: '0.02em',
                    margin: 0,
                    ...adminSans
                  }}
                >
                  ROUND 4: SYSTEM OVERRIDE
                </h2>
                <div style={{ fontSize: '0.75rem', color: '#94a3b8', ...adminSans, marginTop: '0.2rem', fontWeight: '500' }}>
                  KERNEL CODE FILL & MASTER RIDDLE
                </div>
              </div>

              {/* Action Buttons */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem', marginTop: '0.4rem' }}>
                <button
                  onClick={() => handleTransitionState(GAME_STATES.R4_ACTIVE, 4, 'Start Round 4')}
                  style={{
                    background: 'linear-gradient(135deg, #ffb700, #f59e0b)',
                    color: '#000',
                    fontWeight: '700',
                    fontSize: '0.88rem',
                    ...adminSans,
                    padding: '0.75rem 1rem',
                    border: 'none',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer',
                    boxShadow: '0 0 16px rgba(255, 183, 0, 0.35)'
                  }}
                >
                  <Play size={16} fill="#000" /> START ROUND 4
                </button>

                <button
                  onClick={() => handleTransitionState(GAME_STATES.FINAL_RIDDLE, 4, 'Open Final Riddle Protocol')}
                  style={{
                    background: 'rgba(13, 22, 44, 0.85)',
                    border: '1px solid rgba(0, 243, 255, 0.35)',
                    color: 'var(--neon-cyan)',
                    fontSize: '0.82rem',
                    ...adminSans,
                    fontWeight: '700',
                    padding: '0.65rem 1rem',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer'
                  }}
                >
                  <Sparkles size={15} color="var(--neon-cyan)" /> OPEN FINAL RIDDLE
                </button>

                <button
                  onClick={() => handleTransitionState(GAME_STATES.FINAL_RESULT, 4, 'Publish Winners Podium', false)}
                  style={{
                    background: 'rgba(13, 22, 44, 0.85)',
                    border: '1px solid rgba(255, 183, 0, 0.3)',
                    color: 'var(--neon-amber)',
                    fontSize: '0.82rem',
                    ...adminSans,
                    fontWeight: '700',
                    padding: '0.65rem 1rem',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer'
                  }}
                >
                  <Trophy size={15} color="var(--neon-amber)" /> PUBLISH WINNERS PODIUM
                </button>
              </div>
            </div>
          </div>

          {/* ============================================================== */}
          {/* EMERGENCY EVENT OVERRIDE CONTROLS (EXACT FROM REFERENCE) */}
          {/* ============================================================== */}
          <div style={{ marginBottom: '2rem' }}>
            <div
              style={{
                fontSize: '0.74rem',
                color: 'var(--neon-red)',
                ...adminSans,
                textTransform: 'uppercase',
                letterSpacing: '0.05em',
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem',
                marginBottom: '0.6rem',
                fontWeight: '700'
              }}
            >
              <AlertTriangle size={14} color="var(--neon-red)" /> EMERGENCY EVENT OVERRIDE CONTROLS
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
              {/* RESTART EVENT BUTTON */}
              <button
                onClick={handleRestartEvent}
                disabled={isProcessing}
                style={{
                  background: 'linear-gradient(135deg, #ffb700, #f59e0b)',
                  color: '#000',
                  fontWeight: '700',
                  fontSize: '0.9rem',
                  ...adminSans,
                  letterSpacing: '0.03em',
                  padding: '0.85rem',
                  border: 'none',
                  borderRadius: '4px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.6rem',
                  cursor: isProcessing ? 'not-allowed' : 'pointer',
                  opacity: isProcessing ? 0.7 : 1
                }}
              >
                <RotateCcw size={16} /> {isProcessing ? 'RESTARTING...' : 'RESTART EVENT'}
              </button>

              {/* END EVENT BUTTON */}
              <button
                onClick={handleEndEvent}
                disabled={isProcessing}
                style={{
                  background: '#991b1b',
                  color: '#fff',
                  fontWeight: '700',
                  fontSize: '0.9rem',
                  ...adminSans,
                  letterSpacing: '0.03em',
                  padding: '0.85rem',
                  border: 'none',
                  borderRadius: '4px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.6rem',
                  cursor: isProcessing ? 'not-allowed' : 'pointer'
                }}
              >
                <Square size={16} fill="#fff" /> END EVENT
              </button>
            </div>
          </div>

          {/* ============================================================== */}
          {/* LIVE TEAM STATUS MONITOR (EXACT MATCH TO REFERENCE 2) */}
          {/* ============================================================== */}
          <div
            style={{
              background: 'rgba(10, 17, 34, 0.88)',
              border: '1px solid rgba(0, 243, 255, 0.28)',
              borderRadius: '8px',
              padding: '1.4rem',
              backdropFilter: 'blur(12px)',
              boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)'
            }}
          >
            {/* Header and Search Bar */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
                gap: '1rem',
                marginBottom: '1.2rem',
                paddingBottom: '0.8rem',
                borderBottom: '1px solid rgba(0, 243, 255, 0.15)'
              }}
            >
              <div>
                <h3
                  style={{
                    fontSize: '1.15rem',
                    fontWeight: '700',
                    color: 'var(--neon-cyan)',
                    letterSpacing: '0.02em',
                    margin: 0,
                    ...adminSans
                  }}
                >
                  LIVE TEAM STATUS MONITOR
                </h3>
                <div style={{ fontSize: '0.75rem', color: '#94a3b8', ...adminSans, marginTop: '0.2rem', fontWeight: '500' }}>
                  CONNECTED PARTICIPANT AGENTS
                </div>
              </div>

              {/* Search and Bulk Action */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.8rem', flexWrap: 'wrap' }}>
                <div style={{ position: 'relative', width: '240px' }}>
                  <input
                    type="text"
                    placeholder="Search Team Name or ID..."
                    value={teamSearchQuery}
                    onChange={(e) => setTeamSearchQuery(e.target.value)}
                    style={{
                      width: '100%',
                      background: '#070c1a',
                      border: '1px solid rgba(0, 243, 255, 0.3)',
                      borderRadius: '4px',
                      color: '#fff',
                      fontSize: '0.82rem',
                      ...adminSans,
                      padding: '0.45rem 0.6rem 0.45rem 2rem'
                    }}
                  />
                  <Search size={14} style={{ position: 'absolute', left: '0.6rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--neon-cyan)' }} />
                </div>

                <button
                  onClick={() => handleBulkSelect(10)}
                  style={{
                    background: 'rgba(13, 22, 44, 0.85)',
                    border: '1px solid rgba(0, 243, 255, 0.3)',
                    color: 'var(--neon-cyan)',
                    fontSize: '0.75rem',
                    ...adminSans,
                    fontWeight: '600',
                    padding: '0.45rem 0.75rem',
                    borderRadius: '4px',
                    cursor: 'pointer'
                  }}
                >
                  Mark Top 10
                </button>

                <button
                  onClick={() => handleConfirmRoundQualification(currentRound)}
                  disabled={isProcessing || Object.values(selectedTeamsMap).filter(Boolean).length === 0}
                  style={{
                    background: 'linear-gradient(135deg, #00f3ff, #00b4d8)',
                    color: '#020814',
                    fontSize: '0.78rem',
                    ...adminSans,
                    fontWeight: '700',
                    padding: '0.45rem 0.9rem',
                    border: 'none',
                    borderRadius: '4px',
                    cursor: 'pointer'
                  }}
                >
                  Confirm ({Object.values(selectedTeamsMap).filter(Boolean).length}) for Next Round
                </button>
              </div>
            </div>

            {/* Table */}
            <div className="cyber-table-container">
              <table className="cyber-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid rgba(0, 243, 255, 0.2)' }}>
                    <th style={{ color: 'var(--neon-cyan)', ...adminSans, fontSize: '0.75rem', fontWeight: '700', padding: '0.8rem 0.6rem', letterSpacing: '0.04em' }}>TEAM NAME</th>
                    <th style={{ color: 'var(--neon-cyan)', ...adminSans, fontSize: '0.75rem', fontWeight: '700', padding: '0.8rem 0.6rem', letterSpacing: '0.04em' }}>CURRENT ROUND</th>
                    <th style={{ color: 'var(--neon-cyan)', ...adminSans, fontSize: '0.75rem', fontWeight: '700', padding: '0.8rem 0.6rem', letterSpacing: '0.04em' }}>CURRENT SCREEN</th>
                    <th style={{ color: 'var(--neon-cyan)', ...adminSans, fontSize: '0.75rem', fontWeight: '700', padding: '0.8rem 0.6rem', letterSpacing: '0.04em' }}>QUALIFICATION</th>
                    <th style={{ color: 'var(--neon-cyan)', ...adminSans, fontSize: '0.75rem', fontWeight: '700', padding: '0.8rem 0.6rem', letterSpacing: '0.04em' }}>STATUS</th>
                    <th style={{ color: 'var(--neon-cyan)', ...adminSans, fontSize: '0.75rem', fontWeight: '700', padding: '0.8rem 0.6rem', letterSpacing: '0.04em' }}>R1 SCORE</th>
                    <th style={{ color: 'var(--neon-cyan)', ...adminSans, fontSize: '0.75rem', fontWeight: '700', padding: '0.8rem 0.6rem', letterSpacing: '0.04em' }}>R2 SCORE</th>
                    <th style={{ color: 'var(--neon-cyan)', ...adminSans, fontSize: '0.75rem', fontWeight: '700', padding: '0.8rem 0.6rem', letterSpacing: '0.04em' }}>R3 SCORE</th>
                    <th style={{ color: 'var(--neon-cyan)', ...adminSans, fontSize: '0.75rem', fontWeight: '700', padding: '0.8rem 0.6rem', letterSpacing: '0.04em' }}>TOTAL PTS</th>
                    <th style={{ color: 'var(--neon-cyan)', ...adminSans, fontSize: '0.75rem', fontWeight: '700', padding: '0.8rem 0.6rem', textAlign: 'center', letterSpacing: '0.04em' }}>ACTION / SELECT</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredLeaderboard.map((team) => {
                    const isChecked = Boolean(selectedTeamsMap[team.id]);
                    const isEliminated = team.status === 'eliminated';
                    const isSelected = team.status === 'selected';

                    return (
                      <tr
                        key={team.id}
                        style={{
                          borderBottom: '1px solid rgba(255, 255, 255, 0.05)',
                          background: isChecked ? 'rgba(0, 243, 255, 0.08)' : undefined
                        }}
                      >
                        {/* TEAM NAME */}
                        <td style={{ padding: '0.75rem 0.6rem', fontWeight: '600', color: '#fff', ...adminSans }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                            {team.connected && <span className="pulse-dot" style={{ background: 'var(--neon-green)' }} />}
                            <span>{team.team_name}</span>
                          </div>
                          <div style={{ fontSize: '0.68rem', color: '#64748b', ...adminMono }}>
                            ID: {team.id?.slice(0, 10)}...
                          </div>
                        </td>

                        {/* CURRENT ROUND */}
                        <td style={{ padding: '0.75rem 0.6rem', ...adminSans, fontSize: '0.82rem', fontWeight: '500' }}>
                          ROUND 0{team.current_round || 1}
                        </td>

                        {/* CURRENT SCREEN */}
                        <td style={{ padding: '0.75rem 0.6rem', ...adminSans, fontSize: '0.8rem' }}>
                          {isEliminated ? (
                            <span style={{ color: 'var(--neon-red)', fontWeight: '600' }}>Eliminated Screen</span>
                          ) : currentState.includes('WAITING') ? (
                            <span style={{ color: 'var(--neon-amber)', fontWeight: '600' }}>Waiting Room</span>
                          ) : currentState.includes('ACTIVE') ? (
                            <span style={{ color: 'var(--neon-green)', fontWeight: '600' }}>Active Solving</span>
                          ) : (
                            <span style={{ color: 'var(--neon-cyan)', fontWeight: '600' }}>Result Overview</span>
                          )}
                        </td>

                        {/* QUALIFICATION */}
                        <td style={{ padding: '0.75rem 0.6rem' }}>
                          {isSelected ? (
                            <span style={{ color: 'var(--neon-green)', fontWeight: '700', fontSize: '0.78rem', ...adminSans }}>
                              ✓ QUALIFIED
                            </span>
                          ) : isEliminated ? (
                            <span style={{ color: 'var(--neon-red)', fontWeight: '700', fontSize: '0.78rem', ...adminSans }}>
                              ✕ NOT SELECTED
                            </span>
                          ) : (
                            <span style={{ color: '#94a3b8', fontSize: '0.78rem', ...adminSans }}>
                              PENDING
                            </span>
                          )}
                        </td>

                        {/* STATUS */}
                        <td style={{ padding: '0.75rem 0.6rem' }}>
                          <span
                            className={`status-pill status-pill-${team.status || 'active'}`}
                            style={{ fontSize: '0.72rem', ...adminSans }}
                          >
                            {(team.status || 'ACTIVE').toUpperCase()}
                          </span>
                        </td>

                        {/* R1 SCORE */}
                        <td style={{ padding: '0.75rem 0.6rem', ...adminSans, fontVariantNumeric: 'tabular-nums', fontWeight: '600', color: '#cbd5e1' }}>
                          {currentRound >= 1 ? `${team.score || 0}` : '—'}
                        </td>

                        {/* R2 SCORE */}
                        <td style={{ padding: '0.75rem 0.6rem', ...adminSans, fontVariantNumeric: 'tabular-nums', fontWeight: '600', color: '#cbd5e1' }}>
                          {currentRound >= 2 ? `${team.score || 0}` : '—'}
                        </td>

                        {/* R3 SCORE */}
                        <td style={{ padding: '0.75rem 0.6rem', ...adminSans, fontVariantNumeric: 'tabular-nums', fontWeight: '600', color: '#cbd5e1' }}>
                          {currentRound >= 3 ? `${team.score || 0}` : '—'}
                        </td>

                        {/* TOTAL PTS */}
                        <td style={{ padding: '0.75rem 0.6rem', ...adminSans, fontVariantNumeric: 'tabular-nums', fontWeight: '700', color: 'var(--neon-amber)' }}>
                          {team.score || 0} PTS
                        </td>

                        {/* ACTION / SELECT */}
                        <td style={{ padding: '0.75rem 0.6rem', textAlign: 'center' }}>
                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                            <input
                              type="checkbox"
                              checked={isChecked}
                              onChange={() => toggleTeamSelection(team.id)}
                              style={{ width: '16px', height: '16px', cursor: 'pointer', accentColor: 'var(--neon-cyan)' }}
                              title="Mark to advance"
                            />

                            <select
                              value={team.status || 'active'}
                              onChange={(e) => handleTeamStatusChange(team.id, e.target.value)}
                              style={{
                                background: '#070c1a',
                                border: '1px solid rgba(0, 243, 255, 0.3)',
                                borderRadius: '3px',
                                color: 'var(--neon-cyan)',
                                fontSize: '0.72rem',
                                fontWeight: '500',
                                ...adminSans,
                                padding: '0.2rem 0.3rem',
                                cursor: 'pointer'
                              }}
                            >
                              <option value="active">Active</option>
                              <option value="selected">Selected</option>
                              <option value="eliminated">Eliminated</option>
                              <option value="waiting">Waiting</option>
                            </select>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 2: ROUND 1 SELECTION */}
      {/* ============================================================== */}
      {activeTab === 'r1_manage' && (
        <div
          style={{
            background: 'rgba(10, 17, 34, 0.88)',
            border: '1px solid rgba(0, 243, 255, 0.28)',
            borderRadius: '8px',
            padding: '1.8rem',
            backdropFilter: 'blur(12px)',
            position: 'relative',
            zIndex: 1
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem', flexWrap: 'wrap', gap: '1rem' }}>
            <div>
              <h2 style={{ color: 'var(--neon-cyan)', margin: 0, fontSize: '1.25rem', fontWeight: '700', ...adminSans }}>
                ROUND 1 SELECTION & QUALIFICATION
              </h2>
              <p style={{ color: '#8b9bb4', fontSize: '0.85rem', margin: '0.4rem 0 0 0', ...adminSans }}>
                Select qualifying teams from Round 1 to advance to Round 2 (Gridlock Protocol).
              </p>
            </div>

            <div style={{ display: 'flex', gap: '0.6rem', alignItems: 'center', flexWrap: 'wrap' }}>
              <button onClick={() => handleBulkSelect(15)} className="cyber-btn" style={{ padding: '0.45rem 0.85rem', fontSize: '0.78rem', ...adminSans, fontWeight: '600' }}>Top 15</button>
              <button onClick={() => handleBulkSelect(10)} className="cyber-btn" style={{ padding: '0.45rem 0.85rem', fontSize: '0.78rem', ...adminSans, fontWeight: '600' }}>Top 10</button>
              <button onClick={() => handleBulkSelect(null)} className="cyber-btn" style={{ padding: '0.45rem 0.85rem', fontSize: '0.78rem', color: 'var(--neon-red)', ...adminSans, fontWeight: '600' }}>Clear</button>
              <button
                onClick={() => handleConfirmRoundQualification(1, false)}
                disabled={isProcessing}
                style={{
                  background: 'linear-gradient(135deg, #00f3ff, #00b4d8)',
                  color: '#020814',
                  fontWeight: '700',
                  ...adminSans,
                  fontSize: '0.82rem',
                  padding: '0.5rem 1.1rem',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: isProcessing ? 'not-allowed' : 'pointer'
                }}
              >
                1. Confirm & Reveal Secret Word (R1_RESULT)
              </button>
              <button
                onClick={() => handleTransitionState(GAME_STATES.R2_WAITING, 2, 'Advance Qualified Teams to Round 2 Waiting Room')}
                disabled={isProcessing}
                style={{
                  background: 'rgba(13, 22, 44, 0.9)',
                  border: '1px solid rgba(0, 243, 255, 0.45)',
                  color: 'var(--neon-cyan)',
                  fontWeight: '700',
                  ...adminSans,
                  fontSize: '0.82rem',
                  padding: '0.5rem 1.1rem',
                  borderRadius: '4px',
                  cursor: isProcessing ? 'not-allowed' : 'pointer'
                }}
              >
                2. Advance to R2 Waiting Room ➔
              </button>
            </div>
          </div>

          <div className="cyber-table-container">
            <table className="cyber-table" style={{ width: '100%' }}>
              <thead>
                <tr>
                  <th style={{ width: '45px' }}>SELECT</th>
                  <th>RANK</th>
                  <th>TEAM NAME</th>
                  <th>SCORE</th>
                  <th>SOLVED</th>
                  <th>TIME TAKEN</th>
                  <th>STATUS</th>
                </tr>
              </thead>
              <tbody>
                {leaderboard.map((team) => (
                  <tr key={team.id} onClick={() => toggleTeamSelection(team.id)} style={{ cursor: 'pointer', background: selectedTeamsMap[team.id] ? 'rgba(0, 243, 255, 0.08)' : undefined }}>
                    <td><input type="checkbox" checked={Boolean(selectedTeamsMap[team.id])} onChange={() => {}} /></td>
                    <td style={{ ...adminSans, fontWeight: '700', color: 'var(--neon-amber)' }}>#{team.rank}</td>
                    <td style={{ fontWeight: '600', color: '#fff', ...adminSans }}>{team.team_name}</td>
                    <td style={{ color: 'var(--neon-green)', fontWeight: '700', ...adminSans, fontVariantNumeric: 'tabular-nums' }}>{team.score} pts</td>
                    <td style={{ ...adminSans }}>{team.questions_solved} Solved</td>
                    <td style={{ ...adminMono, fontSize: '0.82rem' }}>{Math.floor(team.total_time_seconds / 60)}m {Math.floor(team.total_time_seconds % 60)}s</td>
                    <td><span className={`status-pill status-pill-${team.status}`} style={{ ...adminSans }}>{team.status}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 3: ROUND 2 SELECTION */}
      {/* ============================================================== */}
      {activeTab === 'r2_manage' && (
        <div
          style={{
            background: 'rgba(10, 17, 34, 0.88)',
            border: '1px solid rgba(0, 243, 255, 0.28)',
            borderRadius: '8px',
            padding: '1.8rem',
            backdropFilter: 'blur(12px)',
            position: 'relative',
            zIndex: 1
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem', flexWrap: 'wrap', gap: '1rem' }}>
            <div>
              <h2 style={{ color: 'var(--neon-cyan)', margin: 0, fontSize: '1.25rem', fontWeight: '700', ...adminSans }}>
                ROUND 2 SELECTION & QUALIFICATION
              </h2>
              <p style={{ color: '#8b9bb4', fontSize: '0.85rem', margin: '0.4rem 0 0 0', ...adminSans }}>
                Select qualifying teams from Round 2 to advance to Round 3 (Binary Convergence).
              </p>
            </div>

            <div style={{ display: 'flex', gap: '0.6rem', alignItems: 'center', flexWrap: 'wrap' }}>
              <button onClick={() => handleBulkSelect(10)} className="cyber-btn" style={{ padding: '0.45rem 0.85rem', fontSize: '0.78rem', ...adminSans, fontWeight: '600' }}>Top 10</button>
              <button onClick={() => handleBulkSelect(null)} className="cyber-btn" style={{ padding: '0.45rem 0.85rem', fontSize: '0.78rem', color: 'var(--neon-red)', ...adminSans, fontWeight: '600' }}>Clear</button>
              <button
                onClick={() => handleConfirmRoundQualification(2, false)}
                disabled={isProcessing}
                style={{
                  background: 'linear-gradient(135deg, #00f3ff, #00b4d8)',
                  color: '#020814',
                  fontWeight: '700',
                  ...adminSans,
                  fontSize: '0.82rem',
                  padding: '0.5rem 1.1rem',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: isProcessing ? 'not-allowed' : 'pointer'
                }}
              >
                1. Confirm & Reveal Secret Word (R2_RESULT)
              </button>
              <button
                onClick={() => handleTransitionState(GAME_STATES.R3_WAITING, 3, 'Advance Qualified Teams to Round 3 Waiting Room')}
                disabled={isProcessing}
                style={{
                  background: 'rgba(13, 22, 44, 0.9)',
                  border: '1px solid rgba(0, 243, 255, 0.45)',
                  color: 'var(--neon-cyan)',
                  fontWeight: '700',
                  ...adminSans,
                  fontSize: '0.82rem',
                  padding: '0.5rem 1.1rem',
                  borderRadius: '4px',
                  cursor: isProcessing ? 'not-allowed' : 'pointer'
                }}
              >
                2. Advance to R3 Waiting Room ➔
              </button>
            </div>
          </div>

          <div className="cyber-table-container">
            <table className="cyber-table" style={{ width: '100%' }}>
              <thead>
                <tr>
                  <th style={{ width: '45px' }}>SELECT</th>
                  <th>RANK</th>
                  <th>TEAM NAME</th>
                  <th>SCORE</th>
                  <th>SOLVED</th>
                  <th>TIME TAKEN</th>
                  <th>STATUS</th>
                </tr>
              </thead>
              <tbody>
                {leaderboard.map((team) => (
                  <tr key={team.id} onClick={() => toggleTeamSelection(team.id)} style={{ cursor: 'pointer', background: selectedTeamsMap[team.id] ? 'rgba(0, 243, 255, 0.08)' : undefined }}>
                    <td><input type="checkbox" checked={Boolean(selectedTeamsMap[team.id])} onChange={() => {}} /></td>
                    <td style={{ ...adminSans, fontWeight: '700', color: 'var(--neon-amber)' }}>#{team.rank}</td>
                    <td style={{ fontWeight: '600', color: '#fff', ...adminSans }}>{team.team_name}</td>
                    <td style={{ color: 'var(--neon-green)', fontWeight: '700', ...adminSans, fontVariantNumeric: 'tabular-nums' }}>{team.score} pts</td>
                    <td style={{ ...adminSans }}>{team.questions_solved} Solved</td>
                    <td style={{ ...adminMono, fontSize: '0.82rem' }}>{Math.floor(team.total_time_seconds / 60)}m {Math.floor(team.total_time_seconds % 60)}s</td>
                    <td><span className={`status-pill status-pill-${team.status}`} style={{ ...adminSans }}>{team.status}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 4: ROUND 3 SELECTION */}
      {/* ============================================================== */}
      {activeTab === 'r3_manage' && (
        <div
          style={{
            background: 'rgba(10, 17, 34, 0.88)',
            border: '1px solid rgba(0, 243, 255, 0.28)',
            borderRadius: '8px',
            padding: '1.8rem',
            backdropFilter: 'blur(12px)',
            position: 'relative',
            zIndex: 1
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem', flexWrap: 'wrap', gap: '1rem' }}>
            <div>
              <h2 style={{ color: 'var(--neon-cyan)', margin: 0, fontSize: '1.25rem', fontWeight: '700', ...adminSans }}>
                ROUND 3 SELECTION & QUALIFICATION
              </h2>
              <p style={{ color: '#8b9bb4', fontSize: '0.85rem', margin: '0.4rem 0 0 0', ...adminSans }}>
                Select qualifying teams from Round 3 to advance to Round 4 (System Override).
              </p>
            </div>

            <div style={{ display: 'flex', gap: '0.6rem', alignItems: 'center', flexWrap: 'wrap' }}>
              <button onClick={() => handleBulkSelect(10)} className="cyber-btn" style={{ padding: '0.45rem 0.85rem', fontSize: '0.78rem', ...adminSans, fontWeight: '600' }}>Top 10</button>
              <button onClick={() => handleBulkSelect(null)} className="cyber-btn" style={{ padding: '0.45rem 0.85rem', fontSize: '0.78rem', color: 'var(--neon-red)', ...adminSans, fontWeight: '600' }}>Clear</button>
              <button
                onClick={() => handleConfirmRoundQualification(3, false)}
                disabled={isProcessing}
                style={{
                  background: 'linear-gradient(135deg, #00f3ff, #00b4d8)',
                  color: '#020814',
                  fontWeight: '700',
                  ...adminSans,
                  fontSize: '0.82rem',
                  padding: '0.5rem 1.1rem',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: isProcessing ? 'not-allowed' : 'pointer'
                }}
              >
                1. Confirm & Reveal Secret Word (R3_RESULT)
              </button>
              <button
                onClick={() => handleTransitionState(GAME_STATES.R4_WAITING, 4, 'Advance Qualified Teams to Round 4 Waiting Room')}
                disabled={isProcessing}
                style={{
                  background: 'rgba(13, 22, 44, 0.9)',
                  border: '1px solid rgba(0, 243, 255, 0.45)',
                  color: 'var(--neon-cyan)',
                  fontWeight: '700',
                  ...adminSans,
                  fontSize: '0.82rem',
                  padding: '0.5rem 1.1rem',
                  borderRadius: '4px',
                  cursor: isProcessing ? 'not-allowed' : 'pointer'
                }}
              >
                2. Advance to R4 Waiting Room ➔
              </button>
            </div>
          </div>

          <div className="cyber-table-container">
            <table className="cyber-table" style={{ width: '100%' }}>
              <thead>
                <tr>
                  <th style={{ width: '45px' }}>SELECT</th>
                  <th>RANK</th>
                  <th>TEAM NAME</th>
                  <th>SCORE</th>
                  <th>SOLVED</th>
                  <th>TIME TAKEN</th>
                  <th>STATUS</th>
                </tr>
              </thead>
              <tbody>
                {leaderboard.map((team) => (
                  <tr key={team.id} onClick={() => toggleTeamSelection(team.id)} style={{ cursor: 'pointer', background: selectedTeamsMap[team.id] ? 'rgba(0, 243, 255, 0.08)' : undefined }}>
                    <td><input type="checkbox" checked={Boolean(selectedTeamsMap[team.id])} onChange={() => {}} /></td>
                    <td style={{ ...adminSans, fontWeight: '700', color: 'var(--neon-amber)' }}>#{team.rank}</td>
                    <td style={{ fontWeight: '600', color: '#fff', ...adminSans }}>{team.team_name}</td>
                    <td style={{ color: 'var(--neon-green)', fontWeight: '700', ...adminSans, fontVariantNumeric: 'tabular-nums' }}>{team.score} pts</td>
                    <td style={{ ...adminSans }}>{team.questions_solved} Solved</td>
                    <td style={{ ...adminMono, fontSize: '0.82rem' }}>{Math.floor(team.total_time_seconds / 60)}m {Math.floor(team.total_time_seconds % 60)}s</td>
                    <td><span className={`status-pill status-pill-${team.status}`} style={{ ...adminSans }}>{team.status}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 5: ROUND 4 & FINAL RIDDLE (TOP 10 + WINNERS PODIUM) */}
      {/* ============================================================== */}
      {activeTab === 'r4_manage' && (
        <div
          style={{
            background: 'rgba(10, 17, 34, 0.88)',
            border: '1px solid rgba(0, 243, 255, 0.28)',
            borderRadius: '8px',
            padding: '1.8rem',
            backdropFilter: 'blur(12px)',
            position: 'relative',
            zIndex: 1
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem', flexWrap: 'wrap', gap: '1rem' }}>
            <div>
              <h2 style={{ color: 'var(--neon-cyan)', margin: 0, fontSize: '1.25rem', fontWeight: '700', ...adminSans }}>
                ROUND 4 & FINAL RIDDLE QUALIFICATION
              </h2>
              <p style={{ color: '#8b9bb4', fontSize: '0.85rem', margin: '0.4rem 0 0 0', ...adminSans }}>
                Select Top 10 teams for the final sentence decoding riddle, and declare official podium winners.
              </p>
            </div>

            <div style={{ display: 'flex', gap: '0.6rem', alignItems: 'center', flexWrap: 'wrap' }}>
              <button onClick={() => handleBulkSelect(10)} className="cyber-btn" style={{ padding: '0.45rem 0.85rem', fontSize: '0.78rem', ...adminSans, fontWeight: '600' }}>Top 10</button>
              <button
                onClick={() => handleConfirmRoundQualification(4, false)}
                disabled={isProcessing}
                style={{
                  background: 'linear-gradient(135deg, #00f3ff, #00b4d8)',
                  color: '#020814',
                  fontWeight: '700',
                  ...adminSans,
                  fontSize: '0.82rem',
                  padding: '0.5rem 1.1rem',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: isProcessing ? 'not-allowed' : 'pointer'
                }}
              >
                1. Confirm Top 10 & Reveal Secret Word (R4_RESULT)
              </button>
              <button
                onClick={() => handleTransitionState(GAME_STATES.FINAL_RIDDLE, 4, 'Launch Final Riddle Protocol')}
                disabled={isProcessing}
                style={{
                  background: 'rgba(13, 22, 44, 0.9)',
                  border: '1px solid rgba(255, 183, 0, 0.45)',
                  color: 'var(--neon-amber)',
                  fontWeight: '700',
                  ...adminSans,
                  fontSize: '0.82rem',
                  padding: '0.5rem 1.1rem',
                  borderRadius: '4px',
                  cursor: isProcessing ? 'not-allowed' : 'pointer'
                }}
              >
                2. Launch Final Riddle Protocol ➔
              </button>
            </div>
          </div>

          {/* Declare Winners Box */}
          <div
            style={{
              background: 'rgba(7, 12, 26, 0.9)',
              border: '1px solid rgba(255, 183, 0, 0.35)',
              borderRadius: '6px',
              padding: '1.4rem',
              marginBottom: '1.5rem',
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
              gap: '1rem',
              alignItems: 'end'
            }}
          >
            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', color: 'var(--neon-amber)', marginBottom: '0.3rem', ...adminSans, fontWeight: '700' }}>
                SELECT CHAMPION (WINNER):
              </label>
              <select
                className="cyber-input"
                value={selectedWinnerId}
                onChange={(e) => setSelectedWinnerId(e.target.value)}
                style={{ ...adminSans, fontSize: '0.85rem' }}
              >
                <option value="">-- Choose Champion --</option>
                {leaderboard.map((t) => (
                  <option key={t.id} value={t.id}>
                    #{t.rank} {t.team_name} ({t.score} pts)
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', color: 'var(--neon-cyan)', marginBottom: '0.3rem', ...adminSans, fontWeight: '700' }}>
                SELECT RUNNER-UP (2ND PLACE):
              </label>
              <select
                className="cyber-input"
                value={selectedRunnerUpId}
                onChange={(e) => setSelectedRunnerUpId(e.target.value)}
                style={{ ...adminSans, fontSize: '0.85rem' }}
              >
                <option value="">-- Choose Runner-Up --</option>
                {leaderboard.map((t) => (
                  <option key={t.id} value={t.id}>
                    #{t.rank} {t.team_name} ({t.score} pts)
                  </option>
                ))}
              </select>
            </div>

            <button
              onClick={handleDeclareFinalWinners}
              style={{
                background: 'linear-gradient(135deg, #ffb700, #f59e0b)',
                color: '#000',
                fontWeight: '700',
                ...adminSans,
                fontSize: '0.88rem',
                padding: '0.65rem 1.2rem',
                border: 'none',
                borderRadius: '4px',
                cursor: 'pointer'
              }}
            >
              <Trophy size={15} style={{ display: 'inline', marginRight: '0.3rem' }} /> Publish Winners Podium
            </button>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 6: ROUND SUBMISSIONS & TIMELINES */}
      {/* ============================================================== */}
      {activeTab === 'submissions' && (
        <div
          style={{
            background: 'rgba(10, 17, 34, 0.88)',
            border: '1px solid rgba(0, 243, 255, 0.28)',
            borderRadius: '8px',
            padding: '1.8rem',
            backdropFilter: 'blur(12px)',
            position: 'relative',
            zIndex: 1
          }}
        >
          <h2 style={{ color: 'var(--neon-cyan)', margin: '0 0 1rem 0', fontSize: '1.25rem', fontWeight: '700', ...adminSans }}>
            ROUND SUBMISSIONS & QUALIFICATION MATRIX
          </h2>

          <div className="cyber-table-container" style={{ marginBottom: '2rem' }}>
            <table className="cyber-table" style={{ width: '100%' }}>
              <thead>
                <tr>
                  <th>TEAM NAME</th>
                  <th>ROUND 1 QUALIFICATION</th>
                  <th>ROUND 2 QUALIFICATION</th>
                  <th>ROUND 3 QUALIFICATION</th>
                  <th>ROUND 4 QUALIFICATION</th>
                </tr>
              </thead>
              <tbody>
                {leaderboard.map((team) => {
                  const r1 = selectionHistory.find((s) => s.team_id === team.id && s.round_number === 1);
                  const r2 = selectionHistory.find((s) => s.team_id === team.id && s.round_number === 2);
                  const r3 = selectionHistory.find((s) => s.team_id === team.id && s.round_number === 3);
                  const r4 = selectionHistory.find((s) => s.team_id === team.id && s.round_number === 4);

                  const renderTag = (record) => {
                    if (!record) return <span style={{ color: '#64748b' }}>—</span>;
                    return record.selected ? (
                      <span style={{ color: 'var(--neon-green)', fontWeight: '700', ...adminSans }}>✓ QUALIFIED</span>
                    ) : (
                      <span style={{ color: 'var(--neon-red)', fontWeight: '600', ...adminSans }}>✕ NOT SELECTED</span>
                    );
                  };

                  return (
                    <tr key={team.id}>
                      <td style={{ fontWeight: '600', color: '#fff', ...adminSans }}>{team.team_name}</td>
                      <td>{renderTag(r1)}</td>
                      <td>{renderTag(r2)}</td>
                      <td>{renderTag(r3)}</td>
                      <td>{renderTag(r4)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          <h3 style={{ color: 'var(--neon-amber)', fontSize: '0.95rem', marginBottom: '0.8rem', ...adminSans, fontWeight: '700' }}>
            IMMUTABLE EVENT LOGS
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', maxHeight: '300px', overflowY: 'auto' }}>
            {auditLogs.map((log) => (
              <div
                key={log.id}
                style={{
                  background: 'rgba(7, 12, 26, 0.85)',
                  border: '1px solid rgba(0, 243, 255, 0.15)',
                  padding: '0.6rem 0.9rem',
                  borderRadius: '4px',
                  fontSize: '0.75rem',
                  ...adminMono,
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}
              >
                <div>
                  <span style={{ color: 'var(--neon-amber)', marginRight: '0.6rem' }}>[{log.action}]</span>
                  <span style={{ color: '#cbd5e1' }}>Admin: {log.admin_id} {log.metadata ? JSON.stringify(log.metadata) : ''}</span>
                </div>
                <div style={{ color: '#64748b' }}>{new Date(log.created_at).toLocaleTimeString()}</div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Confirmation Modal */}
      {confirmModalConfig && (
        <ConfirmModal
          isOpen={Boolean(confirmModalConfig)}
          title={confirmModalConfig.title}
          message={confirmModalConfig.message}
          danger={confirmModalConfig.danger}
          onConfirm={confirmModalConfig.onConfirm}
          onCancel={() => setConfirmModalConfig(null)}
        />
      )}
    </div>
  );
}
