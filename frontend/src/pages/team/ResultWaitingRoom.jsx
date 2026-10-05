import React, { useState, useEffect } from 'react';
import { ShieldAlert, Award, Clock, XCircle, CheckCircle, KeyRound, ArrowRight, ShieldCheck } from 'lucide-react';
import { teamService } from '../../services/teamService';
import { GAME_CONFIG } from '../../constants/gameConfig';

export function ResultWaitingRoom({ team, roundNumber, gameSession }) {
  const [teamSelection, setTeamSelection] = useState(null);
  const [roundWord, setRoundWord] = useState(null);
  const [roundProgress, setRoundProgress] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadStatus() {
      if (!team?.id) return;
      try {
        const selections = await teamService.getTeamSelections(team.id);
        const thisRoundSel = selections.find((s) => s.round_number === roundNumber);
        setTeamSelection(thisRoundSel || null);

        // Fetch round progress/stats
        const prog = await teamService.getTeamProgress(team.id, roundNumber);
        setRoundProgress(prog);

        // Fetch team words (only shown if selected)
        const words = await teamService.getTeamWords(team.id);
        const rWord = words.find((w) => w.round_number === roundNumber);
        const fallbackWord = GAME_CONFIG[`ROUND_${roundNumber}`]?.SECRET_WORD;
        setRoundWord(rWord?.word || fallbackWord || null);
      } catch (err) {
        console.error('Error fetching result waiting room status:', err);
      } finally {
        setLoading(false);
      }
    }

    loadStatus();
    const interval = setInterval(loadStatus, 3000);
    return () => clearInterval(interval);
  }, [team?.id, roundNumber]);

  const isSelected = teamSelection?.selected === true;
  const isEliminated = teamSelection?.selected === false || team?.status === 'eliminated';

  return (
    <div
      style={{
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '2.5rem 1.5rem',
        maxWidth: '780px',
        margin: '0 auto',
        width: '100%'
      }}
    >
      <div className="cyber-bg" />
      <div className="cyber-bg-radial" />

      <div
        className="cyber-card"
        style={{
          width: '100%',
          padding: '3rem 2.2rem',
          textAlign: 'center',
          background: 'rgba(9, 15, 30, 0.94)'
        }}
      >
        {/* State 1: Awaiting Admin Evaluation */}
        {!teamSelection && !isEliminated && (
          <div>
            <div
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.5rem',
                color: 'var(--neon-cyan)',
                fontSize: '0.85rem',
                fontFamily: 'var(--font-mono)',
                textTransform: 'uppercase',
                letterSpacing: '1.5px',
                marginBottom: '1rem'
              }}
            >
              <Clock size={16} /> ROUND 0{roundNumber} COMPLETED
            </div>

            <h1
              className="glow-cyan font-display"
              style={{
                fontSize: '2.4rem',
                letterSpacing: '3px',
                marginBottom: '0.8rem'
              }}
            >
              SUBMISSION RECORDED
            </h1>

            <p style={{ color: 'var(--text-muted)', fontSize: '1rem', marginBottom: '2rem', lineHeight: '1.6' }}>
              Your security key decryptions and performance metrics have been securely submitted to Central Command. Organizers are currently compiling live round results.
            </p>

            {/* Performance summary card */}
            {roundProgress && (
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(3, 1fr)',
                  gap: '1rem',
                  marginBottom: '2rem',
                  padding: '1.2rem',
                  borderRadius: '8px',
                  background: 'rgba(0, 243, 255, 0.04)',
                  border: '1px solid rgba(0, 243, 255, 0.2)'
                }}
              >
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)', textTransform: 'uppercase' }}>CHALLENGES SOLVED</div>
                  <div style={{ fontSize: '1.4rem', fontWeight: '700', color: 'var(--neon-green)', fontFamily: 'var(--font-mono)' }}>
                    {roundProgress.solvedCount || 0}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)', textTransform: 'uppercase' }}>SECURITY KEY</div>
                  <div style={{ fontSize: '1.4rem', fontWeight: '700', color: 'var(--neon-cyan)', fontFamily: 'var(--font-mono)' }}>
                    VERIFIED ✓
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)', textTransform: 'uppercase' }}>STATUS</div>
                  <div style={{ fontSize: '1.1rem', fontWeight: '700', color: 'var(--neon-amber)', fontFamily: 'var(--font-mono)', marginTop: '0.2rem' }}>
                    IN REVIEW
                  </div>
                </div>
              </div>
            )}

            {/* Waiting status banner */}
            <div
              style={{
                padding: '1.5rem',
                borderRadius: '8px',
                background: 'rgba(255, 183, 0, 0.08)',
                border: '1px solid rgba(255, 183, 0, 0.3)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: '0.6rem'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', color: 'var(--neon-amber)' }}>
                <span className="pulse-dot" style={{ background: 'var(--neon-amber)' }} />
                <span style={{ fontWeight: '700', letterSpacing: '1px', textTransform: 'uppercase' }}>
                  AWAITING ORGANIZER RESULT DECLARATION
                </span>
              </div>
              <div style={{ fontSize: '0.85rem', color: 'var(--text-dim)', fontFamily: 'var(--font-mono)', lineHeight: '1.5' }}>
                Please remain on this screen. Once selections are confirmed by the game master, qualified teams will unlock their clearance results and secret round word.
              </div>
            </div>
          </div>
        )}

        {/* State 2: Team IS Selected / Qualified */}
        {isSelected && (
          <div>
            <div
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: '64px',
                height: '64px',
                borderRadius: '50%',
                background: 'rgba(0, 255, 136, 0.1)',
                border: '2px solid var(--neon-green)',
                boxShadow: '0 0 20px var(--neon-green-glow)',
                marginBottom: '1.2rem'
              }}
            >
              <CheckCircle size={36} color="var(--neon-green)" />
            </div>

            <h1
              className="glow-green font-display"
              style={{
                fontSize: '2.4rem',
                letterSpacing: '3px',
                marginBottom: '0.8rem'
              }}
            >
              QUALIFIED FOR NEXT ROUND!
            </h1>

            <p style={{ color: 'var(--text-muted)', fontSize: '1rem', marginBottom: '2rem' }}>
              Outstanding performance, <strong style={{ color: '#fff' }}>{team.team_name}</strong>! Your team has been officially selected to advance to Round 0{roundNumber + 1}.
            </p>

            {/* REVEALED SECRET WORD VAULT (ONLY FOR SELECTED TEAMS) */}
            <div
              style={{
                padding: '2rem 1.8rem',
                borderRadius: '12px',
                background: 'linear-gradient(135deg, rgba(0, 255, 136, 0.12) 0%, rgba(0, 243, 255, 0.08) 100%)',
                border: '2px solid var(--neon-green)',
                boxShadow: '0 0 30px rgba(0, 255, 136, 0.25)',
                marginBottom: '2rem',
                textAlign: 'center'
              }}
            >
              <div
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  fontSize: '0.82rem',
                  color: 'var(--neon-cyan)',
                  textTransform: 'uppercase',
                  letterSpacing: '2px',
                  marginBottom: '0.6rem',
                  fontFamily: 'var(--font-mono)'
                }}
              >
                <KeyRound size={16} color="var(--neon-cyan)" /> ROUND 0{roundNumber} SECRET WORD UNLOCKED
              </div>

              <div
                className="glow-green font-display"
                style={{
                  fontSize: 'clamp(2.5rem, 5vw, 3.5rem)',
                  letterSpacing: '8px',
                  color: '#ffffff',
                  textShadow: '0 0 25px var(--neon-green)',
                  margin: '0.6rem 0',
                  fontWeight: '900'
                }}
              >
                {roundWord}
              </div>

              <div
                style={{
                  fontSize: '0.85rem',
                  color: 'var(--neon-green)',
                  fontFamily: 'var(--font-mono)',
                  background: 'rgba(0, 255, 136, 0.1)',
                  padding: '0.5rem 1rem',
                  borderRadius: '6px',
                  display: 'inline-block',
                  marginTop: '0.5rem'
                }}
              >
                ★ NOTE DOWN THIS WORD! You will need all 4 round words to solve the Final Riddle.
              </div>
            </div>

            {/* Performance Metrics */}
            {roundProgress && (
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(2, 1fr)',
                  gap: '1rem',
                  marginBottom: '2rem',
                  padding: '1.2rem',
                  borderRadius: '8px',
                  background: 'rgba(0, 255, 136, 0.04)',
                  border: '1px solid rgba(0, 255, 136, 0.2)'
                }}
              >
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)', textTransform: 'uppercase' }}>QUESTIONS SOLVED</div>
                  <div style={{ fontSize: '1.4rem', fontWeight: '700', color: 'var(--neon-green)', fontFamily: 'var(--font-mono)' }}>
                    {roundProgress.solvedCount || 0}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)', textTransform: 'uppercase' }}>ROUND RESULT</div>
                  <div style={{ fontSize: '1.2rem', fontWeight: '700', color: 'var(--neon-green)', fontFamily: 'var(--font-mono)', marginTop: '0.2rem' }}>
                    CLEARED & ADVANCED ✓
                  </div>
                </div>
              </div>
            )}

            <div
              style={{
                padding: '1rem',
                borderRadius: '6px',
                background: 'rgba(0, 255, 136, 0.08)',
                border: '1px solid rgba(0, 255, 136, 0.3)',
                color: 'var(--neon-green)',
                fontSize: '0.9rem',
                fontFamily: 'var(--font-mono)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '0.5rem'
              }}
            >
              <span className="pulse-dot" /> SYNCHRONIZING WITH NEXT DEFENSIVE LAYER... AWAITING ADMIN LAUNCH
            </div>
          </div>
        )}

        {/* State 3: Team was NOT Selected */}
        {isEliminated && !isSelected && (
          <div>
            <div
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: '64px',
                height: '64px',
                borderRadius: '50%',
                background: 'rgba(255, 42, 95, 0.1)',
                border: '2px solid var(--neon-red)',
                boxShadow: '0 0 20px var(--neon-red-glow)',
                marginBottom: '1.2rem'
              }}
            >
              <XCircle size={36} color="var(--neon-red)" />
            </div>

            <h1
              className="glow-red font-display"
              style={{
                fontSize: '2.4rem',
                letterSpacing: '3px',
                marginBottom: '0.8rem'
              }}
            >
              NOT SELECTED
            </h1>

            <p style={{ color: 'var(--text-main)', fontSize: '1.15rem', marginBottom: '1rem', fontWeight: '600' }}>
              Thank you for participating in Cyber Escape!
            </p>

            <p style={{ color: 'var(--text-muted)', fontSize: '0.95rem', marginBottom: '2rem', lineHeight: '1.6', maxWidth: '580px', margin: '0 auto 2rem auto' }}>
              Your journey in Cyber Escape has concluded for this round. We applaud your technical acumen, effort, and sportsmanship throughout the event.
            </p>

            <div
              style={{
                padding: '1.2rem',
                borderRadius: '8px',
                background: 'rgba(255, 42, 95, 0.08)',
                border: '1px solid var(--border-error)',
                color: 'var(--neon-red)',
                fontSize: '0.9rem',
                fontFamily: 'var(--font-mono)',
                letterSpacing: '1px'
              }}
            >
              DEFENSE EXTRACTION COMPLETE // SESSION LOCKED
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
