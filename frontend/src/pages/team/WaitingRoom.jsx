import React, { useState, useEffect } from 'react';
import { Clock, Shield, AlertCircle, CheckCircle2, Users, KeyRound } from 'lucide-react';
import { roundService } from '../../services/roundService';
import { teamService } from '../../services/teamService';
import { GAME_CONFIG } from '../../constants/gameConfig';

export function WaitingRoom({ team, roundNumber, gameSession }) {
  const [unlockedWords, setUnlockedWords] = useState([]);

  useEffect(() => {
    async function loadWords() {
      if (!team?.id) return;
      try {
        const words = await teamService.getTeamWords(team.id);
        if (words && words.length > 0) {
          setUnlockedWords(words);
        } else if (roundNumber > 1) {
          // Fallback to configured words for previously cleared rounds
          const prev = [];
          for (let r = 1; r < roundNumber; r++) {
            const conf = GAME_CONFIG[`ROUND_${r}`];
            if (conf?.SECRET_WORD) {
              prev.push({ round_number: r, word: conf.SECRET_WORD });
            }
          }
          setUnlockedWords(prev);
        }
      } catch (err) {
        // ignore
      }
    }
    loadWords();
  }, [team?.id, roundNumber]);

  const roundConfig = roundService.getRoundConfig(roundNumber) || {
    TITLE: `ROUND 0${roundNumber}`,
    SUBTITLE: 'Security Protocol Layer',
    DESCRIPTION: 'Prepare your team for the next defensive breach.',
    RULES: ['Await official start authorization from the game master.']
  };

  return (
    <div
      style={{
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '2.5rem 1.5rem',
        maxWidth: '820px',
        margin: '0 auto',
        width: '100%'
      }}
    >
      <div className="cyber-bg" />
      <div className="cyber-bg-radial" />

      {/* Main Waiting Card */}
      <div
        className="cyber-card"
        style={{
          width: '100%',
          padding: '2.8rem 2.2rem',
          textAlign: 'center',
          background: 'rgba(9, 15, 30, 0.88)'
        }}
      >
        {/* Top Round Badge */}
        <div
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.5rem',
            padding: '0.35rem 1rem',
            borderRadius: '20px',
            background: 'rgba(0, 243, 255, 0.1)',
            border: '1px solid rgba(0, 243, 255, 0.3)',
            color: 'var(--neon-cyan)',
            fontSize: '0.8rem',
            fontFamily: 'var(--font-mono)',
            marginBottom: '1rem',
            letterSpacing: '1px'
          }}
        >
          <Shield size={14} /> ROUND 0{roundNumber} PREPARATION
        </div>

        {/* Round Title in CyberFont */}
        <h1
          className="glow-cyan font-display"
          style={{
            fontSize: 'clamp(1.8rem, 4vw, 2.6rem)',
            letterSpacing: '4px',
            marginBottom: '0.4rem'
          }}
        >
          {roundConfig.TITLE}
        </h1>

        <div
          style={{
            fontSize: '1rem',
            color: 'var(--text-muted)',
            marginBottom: '1.8rem',
            textTransform: 'uppercase',
            letterSpacing: '1.5px',
            fontFamily: 'var(--font-mono)'
          }}
        >
          {roundConfig.SUBTITLE}
        </div>

        {/* Team Identity Indicator */}
        <div
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.6rem',
            padding: '0.6rem 1.4rem',
            background: 'rgba(0, 243, 255, 0.05)',
            border: '1px solid var(--border-subtle)',
            borderRadius: '8px',
            marginBottom: '1.5rem'
          }}
        >
          <Users size={16} color="var(--neon-cyan)" />
          <span style={{ color: 'var(--text-dim)', fontSize: '0.85rem' }}>CONNECTED TEAM:</span>
          <span style={{ fontWeight: '700', color: 'var(--neon-cyan)', letterSpacing: '1px' }}>
            {team?.team_name || 'UNVERIFIED TEAM'}
          </span>
        </div>

        {/* VAULT: PREVIOUSLY UNLOCKED SECRET WORDS (ONLY IF PREVIOUS ROUNDS CLEARED) */}
        {roundNumber > 1 && unlockedWords.length > 0 && (
          <div
            style={{
              background: 'rgba(0, 255, 136, 0.06)',
              border: '1px solid rgba(0, 255, 136, 0.3)',
              borderRadius: '8px',
              padding: '1.2rem',
              marginBottom: '1.8rem',
              textAlign: 'center'
            }}
          >
            <div
              style={{
                fontSize: '0.75rem',
                color: 'var(--neon-green)',
                fontFamily: 'var(--font-mono)',
                textTransform: 'uppercase',
                letterSpacing: '1px',
                marginBottom: '0.8rem',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '0.4rem',
                fontWeight: '700'
              }}
            >
              <KeyRound size={15} /> DECRYPTED SECRET WORDS VAULT (FROM QUALIFIED ROUNDS)
            </div>

            <div style={{ display: 'flex', justifyContent: 'center', gap: '0.8rem', flexWrap: 'wrap' }}>
              {unlockedWords.map((uw, idx) => (
                <div
                  key={idx}
                  style={{
                    background: 'rgba(9, 15, 30, 0.95)',
                    border: '1px solid var(--neon-green)',
                    borderRadius: '6px',
                    padding: '0.5rem 1rem',
                    boxShadow: '0 0 12px rgba(0, 255, 136, 0.2)'
                  }}
                >
                  <div style={{ fontSize: '0.68rem', color: 'var(--text-dim)', fontFamily: 'var(--font-mono)' }}>
                    ROUND 0{uw.round_number} WORD:
                  </div>
                  <div style={{ fontSize: '1.2rem', fontWeight: '900', color: 'var(--neon-green)', letterSpacing: '2px', fontFamily: 'var(--font-mono)' }}>
                    {uw.word}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Mission Briefing */}
        <div
          style={{
            textAlign: 'left',
            background: 'rgba(6, 11, 22, 0.8)',
            border: '1px solid rgba(0, 243, 255, 0.12)',
            borderRadius: '8px',
            padding: '1.5rem',
            marginBottom: '2rem'
          }}
        >
          <div
            style={{
              fontSize: '0.8rem',
              color: 'var(--neon-cyan)',
              fontFamily: 'var(--font-mono)',
              textTransform: 'uppercase',
              letterSpacing: '1px',
              marginBottom: '0.6rem',
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem'
            }}
          >
            <AlertCircle size={14} /> MISSION BRIEFING & RULES
          </div>
          <p style={{ color: 'var(--text-main)', fontSize: '0.95rem', marginBottom: '1rem', lineHeight: '1.6' }}>
            {roundConfig.DESCRIPTION}
          </p>
          <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            {roundConfig.RULES.map((rule, idx) => (
              <li
                key={idx}
                style={{
                  display: 'flex',
                  alignItems: 'flex-start',
                  gap: '0.6rem',
                  fontSize: '0.88rem',
                  color: 'var(--text-muted)'
                }}
              >
                <CheckCircle2 size={16} color="var(--neon-green)" style={{ flexShrink: 0, marginTop: '2px' }} />
                <span>{rule}</span>
              </li>
            ))}
          </ul>
        </div>

        {/* Live Status Indicator - No Start Button for Teams */}
        <div
          style={{
            padding: '1.2rem',
            borderRadius: '8px',
            background: 'rgba(255, 183, 0, 0.08)',
            border: '1px solid rgba(255, 183, 0, 0.3)',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '0.5rem'
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', color: 'var(--neon-amber)' }}>
            <span className="pulse-dot" style={{ background: 'var(--neon-amber)' }} />
            <span style={{ fontWeight: '700', letterSpacing: '1.5px', textTransform: 'uppercase', fontSize: '0.9rem' }}>
              WAITING FOR ADMIN TO START ROUND 0{roundNumber}
            </span>
          </div>
          <div style={{ fontSize: '0.8rem', color: 'var(--text-dim)', fontFamily: 'var(--font-mono)' }}>
            The challenge will initialize automatically across all synchronized terminals when the organizer gives authorization.
          </div>
        </div>
      </div>
    </div>
  );
}
