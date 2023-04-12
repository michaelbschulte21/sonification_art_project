# Main_Task.R
# Created by Michael 2023-04-04

library(tidyverse)
# library(tuneR)
# library(rJava)
library(remotes)
# remotes::install_github("UrsWilke/pyramidi")
# remotes::install_github("datadiarist/midiR")

library(pyramidi)
library(midiR)

space <- data.frame(read.csv(file = 'star_classification.csv'), stringsAsFactors = F)

space.classes <- unique(space$class)
# QSO is Quasar
# alpha is longitude or x-value
# delta is latitude or y-value
space %>% ggplot(aes(x = alpha, y = delta, color = class)) + geom_point() + facet_wrap(~class)

##### Below uses delta (y) as time #########
###### Python #######
library(reticulate)
conda_list(conda = "auto")
use_condaenv(condaenv = "base")
# py_install("audiolazy", envname = "base", method = c("conda"), pip = T)
# py_install("midiutil", envname = "base", method = c("conda"), pip = T)

al <- import("audiolazy")
mu <- import("midiutil")

##### Music Functions from Medium Article 1 #####
map_value <- function(value, min_value, max_value, min_result, max_result){
  result <- min_result + (value - min_value)/(max_value - min_value)*(max_result - min_result)
  return(result)
}

map_value_int <- function(value, min_value, max_value, min_result, max_result){
  result <- min_result + (value - min_value)/(max_value - min_value)*(max_result - min_result)
  result <- round(result)
  result <- trunc(result)
  return(result)
}

min_delta <- min(space$delta)
max_delta <- max(space$delta)

space$delta <- space$delta - min_delta

min_delta.new <- min(space$delta)
max_delta.new <- max(space$delta)

##### Time Option 1 #######
bpm <- 60
delta_per_beat <- 0.25
song_length <- max_delta.new/(bpm*delta_per_beat)
print(paste0(song_length))

##### Time Option 2 ########
duration_beats <- 420 # Desired duration in beats (actually, onset of last note)
space$time_data_int <- map_value_int(value = space$delta, min_value = min(space$delta), max_value = max(space$delta), min_result = 0, max_result = duration_beats)
space$time_data <- map_value(value = space$delta, min_value = min(space$delta), max_value = max(space$delta), min_result = 0, max_result = duration_beats)
duration_sec <- duration_beats*60/bpm
print(paste0("Duration: ", duration_sec, " seconds"))
print(paste0("Duration: ", duration_sec/60, " minutes"))


# Normalize the alpha data
space.new <- space %>% select(-c(obj_ID, run_ID, rerun_ID, cam_col, field_ID, spec_obj_ID, fiber_ID))
space.new$alpha <- map_value(value = space.new$alpha, min_value = min(space.new$alpha), max_value = max(space.new$alpha), min_result = 0, max_result = 1)
# space.new %>% ggplot(aes(x = alpha, y = delta, color = class)) + geom_point() + facet_wrap(~class)

# Velocity mapping
min_velocity <- 64
max_velocity <- 127
space.new$velocity <- map_value_int(value = space.new$redshift, min_value = min(space.new$redshift), max_value = max(space.new$redshift), min_result = min_velocity, max_result = max_velocity)

# space.new %>% ggplot(aes(x = alpha, y = time_data, color = class)) + geom_point() + facet_wrap(~class)

##### MIDI Stuff #######
# Use Lydian Mode in C (F, G, A, B, C, D, E)
# MIDI range is C-1 to G9
# Lowest double bass note in E1
# Highest piccolo note is C8

note_letters <- c('F', 'G', 'A', 'B', 'C', 'D', 'E')
octave_num <- c(1:8)
octave_number <- c()
for(num in octave_num){
  for(n in 1:length(note_letters)){
    octave_number <- append(octave_number, num)
  }
}
paste("'", note_letters, octave_number, "'", sep = "", collapse = ", ")

note_names <- c('F1', 'G1', 'E1', 'F2', 'G2', 'A2', 'B2', 'C2', 'D2', 'E2', 'F3', 'G3', 'A3', 'B3', 'C3', 'D3', 'E3', 'F4', 'G4', 'A4', 'B4', 'C4', 'D4', 'E4', 'F5', 'G5', 'A5', 'B5', 'C5', 'D5', 'E5', 'F6', 'G6', 'A6', 'B6', 'C6', 'D6', 'E6', 'F7', 'G7', 'A7', 'B7', 'C7', 'D7', 'E7', 'A8', 'B8', 'C8')

note_midi_vals <- al$str2midi(note_names)

note_midi_vals <- note_midi_vals[order(note_midi_vals)]

space.new$midi_vals <- map_value_int(value = space.new$alpha, min_value = min(space.new$alpha), max_value = max(space.new$alpha), min_result = 0, max_result = length(note_midi_vals) - 1)
space.new$midi_valsR <- map_value_int(value = space.new$alpha, min_value = min(space.new$alpha), max_value = max(space.new$alpha), min_result = 1, max_result = length(note_midi_vals))
space.new$pitch_num <- note_midi_vals[space.new$midi_valsR]

# space.new$duration <- map_value(value = space.new$redshift, min_value = min(space.new$redshift), max_value = max(space.new$redshift), min_result = 0.25, max_result = 4)

# space.new %>% ggplot(aes(x = midi_vals, y = time_data, color = class)) + geom_point() + facet_wrap(~class)
space.new %>% ggplot(aes(x = pitch_num, y = time_data, color = class)) + geom_point() + facet_wrap(~class)

midi.info.all <- space.new %>% select(c(class, midi_vals, midi_valsR, pitch_num, time_data_int, time_data, velocity))
midi.info.all <- midi.info.all[order(midi.info.all$time_data),]
row.names(midi.info.all) <- NULL
midi.info.all <- midi.info.all %>% rename('classes' = 'class')

x <- midi.info.all %>% plyr::count(c('classes', 'pitch_num', 'time_data_int'))

midi.info.all <- merge(x = midi.info.all,
                       y = x,
                       by = c('classes', 'pitch_num', 'time_data_int'),
                       all.x = T,
                       all.y = T,
                       sort = F)

midi.info.all <- midi.info.all[order(midi.info.all$time_data_int),]
row.names(midi.info.all) <- NULL
midi.info.all$duration <- map_value(value = midi.info.all$freq, min_value = min(midi.info.all$freq), max_value = max(midi.info.all$freq), min_result = 0.25, max_result = 4)

stars <- midi.info.all %>% filter(classes == "STAR")
rownames(stars) <- NULL
quasar <- midi.info.all %>% filter(classes == "QSO")
rownames(quasar) <- NULL
galaxy <- midi.info.all %>% filter(classes == "GALAXY")
rownames(galaxy) <- NULL

midi.stats <- data.frame(obj.type = c('STAR', 'QSO', 'GALAXY'), 
                         min_midi_note = c(min(stars$pitch_num), min(quasar$pitch_num), min(galaxy$pitch_num)), 
                         max_midi_note = c(max(stars$pitch_num), max(quasar$pitch_num), max(galaxy$pitch_num)))

midi.stats$min_note <- al$midi2str(midi.stats$min_midi_note)
midi.stats$max_note <- al$midi2str(midi.stats$max_midi_note)

midi.stats$instrument.class <- c('brass', 'woodwind', 'strings')

midi.stats$instrument.class.min_note <- c('D1', 'Bb1', 'A0')
midi.stats$instrument.class.max_note <- c('D6', 'C8', 'C7')
midi.stats$needs_extra_instrument <- c(1, 0, 1)
midi.stats$extra_instrument <- c('Celesta', NA, 'Harp')
midi.stats
# duration could be count of occurances at a time x

celesta <- stars %>% filter(pitch_num > 86)
stars <- stars %>% filter(pitch_num <= 86)
rownames(stars) <- NULL

xylophone <- galaxy %>% filter(pitch_num > 96)
rownames(harp) <- NULL
galaxy <- galaxy %>% filter(pitch_num <= 96)
rownames(galaxy) <- NULL
# stars.short <- stars %>% filter(duration< 1)
# rownames(stars.short) <- NULL
# stars.long <- stars %>% filter(duration >= 1)
# rownames(stars.long) <- NULL
# quasar.short <- quasar %>% filter(duration < 1)
# rownames(quasar.short) <- NULL
# quasar.long <- quasar %>% filter(duration >= 1)
# rownames(quasar.long) <- NULL
# galaxy.short <- galaxy %>% filter(duration < 0.5)
# rownames(galaxy.short) <- NULL
# galaxy.mid <- galaxy %>% filter(duration < 1 & duration >= 0.5)
# rownames(galaxy.mid) <- NULL
# galaxy.long <- galaxy %>% filter(duration >= 1)
# rownames(galaxy.long) <- NULL
brass <- data.frame(instrument = c('tuba', 'trombone bass', 'trombone tenor', 'trumpet', 'horns'),
                    min_note = c('D1', 'E1', 'G1', 'E3', 'A1'),
                    max_note = c('E4', 'G4', 'D5', 'D6', 'F5'))
brass$id <- 1:nrow(brass)
brass$min_note.midi <- al$str2midi(brass$min_note)
brass$max_note.midi <- al$str2midi(brass$max_note)
brass <- brass[order(brass$min_note.midi),]
rownames(brass) <- NULL

woodwind <- data.frame(instrument = c('bassoon', 'clarinet', 'oboe', 'flute', 'piccolo'),
                       min_note = c('B1', 'D3', 'B3', 'C4', 'D5'),
                       max_note = c('D5', 'E6', 'F6', 'C7', 'C8'))
woodwind$id <- 1:nrow(woodwind)
woodwind$min_note.midi <- al$str2midi(woodwind$min_note)
woodwind$max_note.midi <- al$str2midi(woodwind$max_note)
woodwind <- woodwind[order(woodwind$min_note.midi),]
rownames(woodwind) <- NULL

strings <- data.frame(instrument = c('violin1', 'violin2', 'viola', 'cello', 'bass'),
                      min_note = c('G3', 'G3', 'C3', 'C2', 'C1'),
                      max_note = c('C7', 'C7', 'F6', 'A5', 'F3'))
strings$id <- 1:nrow(strings)
strings$min_note.midi <- al$str2midi(strings$min_note)
strings$max_note.midi <- al$str2midi(strings$max_note)
strings <- strings[order(strings$min_note.midi),]
rownames(strings) <- NULL

harp <- quasar %>% filter(pitch_num < min(woodwind$min_note.midi))
quasar <- quasar %>% filter(pitch_num >= min(woodwind$min_note.midi))
glockenspiel <- quasar %>% filter(pitch_num > max(woodwind$max_note.midi))
quasar <- quasar %>% filter(pitch_num <= max(woodwind$max_note.midi))
rownames(harp) <- NULL
rownames(glockenspiel) <- NULL
rownames(quasar) <- NULL


stars$instrument.id <- NA
quasar$instrument.id <- NA
galaxy$instrument.id <- NA

set.seed(123)

get_instruments <- function(space.df, orch_section){
  assigned_ids <- numeric(nrow(space.df))
  for(i in seq_along(space.df$pitch_num)){
    possible_ids <- orch_section[orch_section$min_note.midi <= space.df$pitch_num[i] & space.df$pitch_num[i] <= orch_section$max_note.midi, "id"]
    assigned_ids[i] <- sample(possible_ids, size = 1)
  }
  return(assigned_ids)
}

stars$instrument.id <- get_instruments(space.df = stars, orch_section = brass)
quasar$instrument.id <- get_instruments(space.df = quasar, orch_section = woodwind)
galaxy$instrument.id <- get_instruments(space.df = galaxy, orch_section = strings)

# joined_df <- merge(stars, brass, by = NULL, all.x = T, all.y = F)
# joined_df <- joined_df[joined_df$pitch_num >= joined_df$min_note.midi &
#                          joined_df$pitch_num <= joined_df$max_note.midi, ]
# joined_df$instrument.id <- sample(x = joined_df$id, size = nrow(joined_df), replace = TRUE)
# output <- distinct(joined_df[, c('classes', 'pitch_num', 'time_data_int', 'time_data', 'velocity', 'duration', 'instrument.id')])

tempo <- data.frame(bpm = 60)

brass <- brass[order(brass$id),]
rownames(brass) <- NULL
woodwind <- woodwind[order(woodwind$id),]
rownames(woodwind) <- NULL
strings <- strings[order(strings$id),]
rownames(strings) <- NULL

for(i in 1:nrow(brass)){
  df <- stars %>% filter(instrument.id == i)
  rownames(df) <- NULL
  write.csv(df, file = paste0("stars_", brass$instrument[i],"_midi_values.csv"))
  assign(paste0("stars_", brass$instrument[i]), df)
}

write.csv(celesta, file = 'celesta_midi_values.csv')

for(i in 1:nrow(woodwind)){
  df <- quasar %>% filter(instrument.id == i)
  rownames(df) <- NULL
  write.csv(df, file = paste0("quasar_", woodwind$instrument[i],"_midi_values.csv"))
  assign(paste0("quasar_", woodwind$instrument[i]), df)
}

write.csv(harp, file = 'harp_midi_values.csv')
write.csv(glockenspiel, file = 'glock_midi_values.csv')

for(i in 1:nrow(strings)){
  df <- galaxy %>% filter(instrument.id == i)
  rownames(df) <- NULL
  write.csv(df, file = paste0("galaxy_", strings$instrument[i],"_midi_values.csv"))
  assign(paste0("galaxy_", strings$instrument[i]), df)
}

write.csv(xylophone, file = 'xylo_midi_values.csv')


write.csv(tempo, file = "tempo.csv")

# py_run_file("space_midi.py")
