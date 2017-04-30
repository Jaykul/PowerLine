@{
  Branch = (PSObject @{
    Background = 'Blue'
    Foreground = 'Yellow'
    Object = " "
  })
  BehindBy = (PSObject @{
    Background = 'Blue'
    Foreground = 'DarkRed'
    Object = '▼'
  })
  After = (PSObject @{
    Background = (RgbColor Black)
    Foreground = (RgbColor White)
    Object = ''
  })
  Before = (PSObject @{
    Background = (RgbColor Black)
    Foreground = (RgbColor White)
    Object = ''
  })
  UnstagedChanges = (PSObject @{
    Background = 'Cyan'
    Foreground = 'White'
  })
  HideZero = $True
  NoStatus = (PSObject @{
    Background = ""
    Foreground = ""
    Object = ''
  })
  Index = (PSObject @{
    Background = (RgbColor Black)
    Foreground = (RgbColor Green)
  })
  BeforeChanges = (PSObject @{
    Background = 'Cyan'
    Foreground = 'Blue'
    Object = ''
  })
  Working = (PSObject @{
    Background = (RgbColor Black)
    Foreground = (RgbColor Green)
  })
  StagedChanges = (PSObject @{
    Background = 'Cyan'
    Foreground = 'Yellow'
  })
  AheadBy = (PSObject @{
    Background = 'Blue'
    Foreground = 'Yellow'
    Object = '▲'
  })
  Separator = (PSObject @{
    Background = 'Cyan'
    Foreground = 'Blue'
    Object = ''
  })
}
