
if(
  equals(outputs('Compose_Failure_Count'), 0),
  if(
    equals(outputs('Compose_Success_Count'), 0),
    'NO ACTIVITY: No completed builds during this reporting window.',
    concat(
      '🎊 PERFECT RUN! Congratulations, team! All ',
      string(outputs('Compose_Success_Count')),
      ' builds completed successfully with zero failures.'
    )
  ),
  if(
    greaterOrEquals(outputs('Compose_Failure_Count'), 10),
    '🔴 CRITICAL: 10 or more build failures recorded. Prioritize investigation.',
    if(
      greaterOrEquals(outputs('Compose_Failure_Count'), 5),
      '🟠 ATTENTION: Elevated failure count. Review recurring failure steps.',
      if(
        greaterOrEquals(outputs('Compose_Failure_Count'), 2),
        '🟡 WATCH: Multiple build failures recorded. Review the breakdown below.',
        'MONITOR: One build failure recorded. Review the failure details.'
      )
    )
  )
)
