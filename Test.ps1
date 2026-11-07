trap {
    Write-Output $_.InvocationInfo.PositionMessage
    throw
}