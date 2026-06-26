import { buildBracketGridLayout, roundTitleAtIndex } from "./bracketUtils";
import "../../../components/TournamentBracket.css";

function SkeletonJoin({ simple }) {
  return (
    <div className={`tb-skeleton-join ${simple ? "tb-skeleton-join--simple" : ""}`} aria-hidden>
      <span className="tb-skeleton-line tb-skeleton-line--in1" />
      <span className="tb-skeleton-line tb-skeleton-line--in2" />
      <span className="tb-skeleton-line tb-skeleton-line--v" />
      <span className="tb-skeleton-line tb-skeleton-line--out" />
    </div>
  );
}

function SkeletonMatchCard() {
  return (
    <div className="tb-skeleton-card" aria-hidden>
      <div className="tb-skeleton-card__head">
        <span className="tb-skeleton-pulse tb-skeleton-pulse--sm" />
        <span className="tb-skeleton-pulse tb-skeleton-pulse--badge" />
      </div>
      <div className="tb-skeleton-card__body">
        <div className="tb-skeleton-row">
          <span className="tb-skeleton-pulse tb-skeleton-pulse--avatar" />
          <span className="tb-skeleton-pulse tb-skeleton-pulse--name" />
          <span className="tb-skeleton-pulse tb-skeleton-pulse--score" />
        </div>
        <div className="tb-skeleton-row">
          <span className="tb-skeleton-pulse tb-skeleton-pulse--avatar" />
          <span className="tb-skeleton-pulse tb-skeleton-pulse--name" />
          <span className="tb-skeleton-pulse tb-skeleton-pulse--score" />
        </div>
      </div>
    </div>
  );
}

/**
 * Animated skeleton mimicking the tournament bracket grid.
 * @param {{ bracketSize?: number, variant?: string }} props
 */
export default function BracketSkeletonLoader({ bracketSize = 8, variant = "manager" }) {
  const mockBracket = {
    bracketSize,
    rounds: (() => {
      const numRounds = Math.log2(bracketSize);
      const rounds = [];
      for (let r = 0; r < numRounds; r++) {
        const count = bracketSize / 2 ** (r + 1);
        rounds.push({
          roundIndex: r,
          title: roundTitleAtIndex(bracketSize, r),
          matches: Array.from({ length: count }, (_, m) => ({ id: `sk-${r}-${m}` })),
        });
      }
      return rounds;
    })(),
  };

  const gridLayout = buildBracketGridLayout(mockBracket);
  if (!gridLayout) return null;

  const { numRows, numRounds, colTemplate, rowTemplate } = gridLayout;
  const rounds = mockBracket.rounds;
  const pageClass = variant === "manager" ? "tb-bracket-page tb-bracket-page--manager" : "tb-bracket-page";

  return (
    <div className={`${pageClass} tb-bracket-skeleton-wrap`} dir="rtl" aria-busy="true" aria-label="جاري تحميل الشجرة">
      <div className="tb-bracket-scroll">
        <div className="tb-bracket-grid-wrap" dir="ltr">
          <div
            className="tb-bracket-grid"
            style={{
              gridTemplateColumns: colTemplate,
              gridTemplateRows: rowTemplate,
            }}
          >
            {rounds.map((round, r) => (
              <div
                key={`sk-h-${round.roundIndex}`}
                className="tb-bracket-grid-head tb-skeleton-pulse tb-skeleton-pulse--head"
                style={{ gridRow: 1, gridColumn: r * 2 + 1 }}
              />
            ))}

            {rounds.flatMap((round, r) =>
              round.matches.map((match, m) => {
                const span = numRows / round.matches.length;
                const rowStart = 2 + m * span;
                const isFirstRound = r === 0;
                const isLastRound = r === numRounds - 1;

                return (
                  <div
                    key={match.id}
                    className="tb-grid-match-cell"
                    style={{ gridRow: `${rowStart} / span ${span}`, gridColumn: r * 2 + 1 }}
                  >
                    {!isFirstRound ? (
                      <div className="tb-conn-gutter tb-conn-gutter--in" aria-hidden>
                        <span className="tb-skeleton-line tb-skeleton-line--conn-in" />
                      </div>
                    ) : null}
                    <div className="tb-match-card-slot">
                      <SkeletonMatchCard />
                    </div>
                    {!isLastRound ? (
                      <div className="tb-conn-gutter tb-conn-gutter--out" aria-hidden>
                        <span className="tb-skeleton-line tb-skeleton-line--conn-out" />
                      </div>
                    ) : null}
                  </div>
                );
              }),
            )}

            {numRounds > 1 &&
              rounds.slice(0, -1).flatMap((_, r) => {
                const next = rounds[r + 1];
                const parents = next.matches.length;
                const spanParent = numRows / parents;
                const simple = parents === 1;
                return next.matches.map((__, m) => (
                  <div
                    key={`sk-join-${r}-${m}`}
                    className="tb-grid-join-cell"
                    style={{ gridRow: `${2 + m * spanParent} / span ${spanParent}`, gridColumn: r * 2 + 2 }}
                  >
                    <SkeletonJoin simple={simple} />
                  </div>
                ));
              })}
          </div>
        </div>
      </div>
    </div>
  );
}
