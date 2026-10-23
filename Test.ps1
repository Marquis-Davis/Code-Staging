# Original form Size from the designer
$designWidth = 1193
$designHeight = 941

$form = $this
$screen = [System.Windows.Forms.Screen]::FromControl($form).WorkingArea

$borderWidth = $form.Width - $form.ClientSize.Width
$borderHeight = $form.Height - $form.ClientSize.Height

$clientWidth = $designWidth - $borderWidth
$clientHeight = $designHeight - $borderHeight

$scale = [Math]::Min(
    ($screen.Width - $borderWidth - 20) / $clientWidth,
    ($screen.Height - $borderHeight - 20) / $clientHeight
)
$scale = [Math]::Min(1.0, $scale)

$form.SuspendLayout()
$form.MinimumSize = [System.Drawing.Size]::Empty
$form.MaximumSize = [System.Drawing.Size]::Empty

$form.Scale([System.Drawing.SizeF]::new($scale, $scale))
$form.ClientSize = [System.Drawing.Size]::new(
    [int]($clientWidth * $scale),
    [int]($clientHeight * $scale)
)

$form.ResumeLayout($true)
$form.Location = [System.Drawing.Point]::new(
    [int]($screen.Left + ($screen.Width - $form.Width) / 2),
    [int]($screen.Top + ($screen.Height - $form.Height) / 2)
)