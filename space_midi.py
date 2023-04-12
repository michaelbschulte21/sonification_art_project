import pandas as pd
from midiutil import MIDIFile 

stars_tuba = pd.read_csv("stars_tuba_midi_values.csv")
stars_tb = pd.read_csv("stars_trombone bass_midi_values.csv")
stars_tt = pd.read_csv("stars_trombone tenor_midi_values.csv")
stars_trumpet = pd.read_csv("stars_trumpet_midi_values.csv")
stars_horns = pd.read_csv("stars_horns_midi_values.csv")
celesta = pd.read_csv("celesta_midi_values.csv")

quasar_bassoon = pd.read_csv("quasar_bassoon_midi_values.csv")
quasar_clarinet = pd.read_csv("quasar_clarinet_midi_values.csv")
quasar_oboe = pd.read_csv("quasar_oboe_midi_values.csv")
quasar_flute = pd.read_csv("quasar_flute_midi_values.csv")
quasar_piccolo = pd.read_csv("quasar_piccolo_midi_values.csv")
harp = pd.read_csv("harp_midi_values.csv")
glock = pd.read_csv("glock_midi_values.csv")

galaxy_v1 = pd.read_csv("galaxy_violin1_midi_values.csv")
galaxy_v2 = pd.read_csv("galaxy_violin2_midi_values.csv")
galaxy_viola = pd.read_csv("galaxy_viola_midi_values.csv")
galaxy_cello = pd.read_csv("galaxy_cello_midi_values.csv")
galaxy_bass = pd.read_csv("galaxy_bass_midi_values.csv")
xylo = pd.read_csv("xylo_midi_values.csv")

tempo = pd.read_csv("tempo.csv")

tempo = tempo.bpm[0]

def create_space_midi(df, tempo, filename):
  my_midi_file = MIDIFile(1) # one track
  my_midi_file.addTempo(track = 0, time = 0, tempo = tempo) 

  for i in range(len(df.time_data)):
    my_midi_file.addNote(track = 0, channel = 0, time = df.time_data[i], pitch = df.pitch_num[i], volume = df.velocity[i], duration = df.duration[i])
  
  filename = filename
  with open('MIDI/' + filename + '.mid', "wb") as f:
    my_midi_file.writeFile(f)
    

# Create MIDI files
# stars
create_space_midi(df = stars_tuba, tempo = tempo, filename = "stars_midi.tuba")
create_space_midi(df = stars_tb, tempo = tempo, filename = "stars_midi.trombone_bass")
create_space_midi(df = stars_tt, tempo = tempo, filename = "stars_midi.trombone_tenor")
create_space_midi(df = stars_trumpet, tempo = tempo, filename = "stars_midi.trumpet")
create_space_midi(df = stars_horns, tempo = tempo, filename = "stars_midi.horns")
create_space_midi(df = celesta, tempo = tempo, filename = "celesta_midi")

# quasars
create_space_midi(df = quasar_bassoon, tempo = tempo, filename = "quasar_midi.bassoon")
create_space_midi(df = quasar_clarinet, tempo = tempo, filename = "quasar_midi.clarinet")
create_space_midi(df = quasar_oboe, tempo = tempo, filename = "quasar_midi.oboe")
create_space_midi(df = quasar_flute, tempo = tempo, filename = "quasar_midi.flute")
create_space_midi(df = quasar_piccolo, tempo = tempo, filename = "quasar_midi.piccolo")
create_space_midi(df = harp, tempo = tempo, filename = "harp_midi")
create_space_midi(df = glock, tempo = tempo, filename = "glock_midi")

# galaxy
create_space_midi(df = galaxy_v1, tempo = tempo, filename = "galaxy_midi.violin1")
create_space_midi(df = galaxy_v2, tempo = tempo, filename = "galaxy_midi.violin2")
create_space_midi(df = galaxy_viola, tempo = tempo, filename = "galaxy_midi.viola")
create_space_midi(df = galaxy_cello, tempo = tempo, filename = "galaxy_midi.cello")
create_space_midi(df = galaxy_bass, tempo = tempo, filename = "galaxy_midi.bass")
create_space_midi(df = xylo, tempo = tempo, filename = "xylo_midi")
