
clear all;
close all;
args.char_filepath = 'C:\Users\Gam9LG\Documents\TestData\MeaTroubleshooting\080224\allego_1__uid0802-12-56-20_data.xdat';
eeg = util_allegoXDatAddEvents_chirp(args.char_filepath);