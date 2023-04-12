#!/bin/bash

killall conky
sleep 2s
		
conky -c $HOME/.config/conky/Sirius/Sirius.conf &> /dev/null &
conky -c $HOME/.config/conky/Sirius/Sirius2.conf &> /dev/null &
