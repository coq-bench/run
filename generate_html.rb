require_relative 'backup'

backup = Backup.new("csv")
p backup
p backup.packages
p backup.read_history("coq-aac-tactics", "1.0.0")