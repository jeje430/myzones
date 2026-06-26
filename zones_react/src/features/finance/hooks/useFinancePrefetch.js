import { useEffect, useRef, useState } from "react";
import { FINANCE_DATA_EVENT, prefetchFinanceMonth, refetchFinanceData } from "../data/financeApiCache";

export function useFinancePrefetch(year, month, granularity = "daily", packagePeriod = "monthly") {
  const [readyTick, setReadyTick] = useState(0);
  const paramsRef = useRef({ year, month, granularity, packagePeriod });
  paramsRef.current = { year, month, granularity, packagePeriod };

  useEffect(() => {
    let active = true;

    prefetchFinanceMonth(year, month, granularity, packagePeriod).then(() => {
      if (active) setReadyTick((tick) => tick + 1);
    });

    return () => {
      active = false;
    };
  }, [year, month, granularity, packagePeriod]);

  useEffect(() => {
    let debounceTimer = null;
    let active = true;

    const sync = () => {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(() => {
        const { year: y, month: m, granularity: g, packagePeriod: p } = paramsRef.current;
        refetchFinanceData(y, m, g, p).then(() => {
          if (active) setReadyTick((tick) => tick + 1);
        });
      }, 80);
    };

    window.addEventListener(FINANCE_DATA_EVENT, sync);
    return () => {
      active = false;
      clearTimeout(debounceTimer);
      window.removeEventListener(FINANCE_DATA_EVENT, sync);
    };
  }, []);

  return readyTick;
}
