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
    Background = (ConsoleColor Black)
    Foreground = (ConsoleColor White)
    Object = ''
  })
  Before = (PSObject @{
    Background = (ConsoleColor Black)
    Foreground = (ConsoleColor White)
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
    Background = (ConsoleColor Black)
    Foreground = (ConsoleColor Green)
  })
  BeforeChanges = (PSObject @{
    Background = 'Cyan'
    Foreground = 'Blue'
    Object = ''
  })
  Working = (PSObject @{
    Background = (ConsoleColor Black)
    Foreground = (ConsoleColor Green)
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
