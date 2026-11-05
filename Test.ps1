$now = [DateTime]::UtcNow

$policy = @{
    UpdatedUTC     = $now.ToString('o')
    LastUpdated    = $now.ToString('MM/dd/yyyy hh:mm tt') + ' UTC'
    Boundaries     = @($boundaries)
}