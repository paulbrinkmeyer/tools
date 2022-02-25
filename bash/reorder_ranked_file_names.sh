#!/bin/bash

#-------------------------------------------------------------------------------
# Release Notes:
#
#----- 2011-04-24 - Paul Brinkmeyer --------------------------------------------
# - First release!
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# The reason for the forever loop is because the exit command in Cygwin closes
# X windows. This most likely isn't the desired behavior. If the script comes
# to the end without reaching an "exit" it won't close X windows. Therefore,
# "break"s from the for loop are used instead of "exit"s.
#-------------------------------------------------------------------------------
(
for ((;;))
do
	#-----------------------------------------
	# Check to make sure arguments were given
	#-----------------------------------------
	if test $# = 0
	then
		echo "Error: No argument was given"
		break
	fi

	#------------------------------------------------------
	# Check to make sure no more than 1 argument was given
	#------------------------------------------------------
	if [[ $# > 1 ]]
	then
		echo "Error: Too many arguements were given: arguments=\"$@\""
		break
	fi

	#------------------------------------------------------------------------
	# print all the ranks in the current directory with the given file name
	#------------------------------------------------------------------------
	(
		IFS=$'\n'
		for fileName in "$@ - *"
		do
			printf "%s\n" $fileName
		done
	)

	#-----------------------------------------------
	# Ask for the rank number to change (startRank)
	#-----------------------------------------------
	echo "Enter the rank number you want to change (enter 'q' to quit):"
	read startRank

	originalIFS=$IFS
	IFS=$'\n'

	while test $startRank != "q"
	do
		#check to see if the startRank is a number
		if [ $startRank -eq $startRank 2> /dev/null ]
		then
			if test -w "$@ - $startRank.jpg"
			then
				echo "'$startRank' is a valid rank."
				break
			else
				echo "You don't have write access to this file. Enter a different rank number (enter 'q' to quit):"
			fi
		else
			echo "'$startRank' is not a number. Enter a valid rank number (enter 'q' to quit):"
		fi
		read startRank
	done

	#-------------------------------------------
	# Check to see if the user wanted to quit.
	#-------------------------------------------
	if test $startRank = "q"
	then
		echo "Quit early was chosen."
		echo "DONE"
		break
	fi

	IFS=$originalIFS

	#------------------------------------------------
	# Ask for the rank number to switch to (newRank)
	#------------------------------------------------
	echo "Enter the rank you want to switch to. (enter 'q' to quit with out changing anything)"
	read newRank

	while test $newRank != "q"
	do
		#check to see if the newRank is a number
		if [ $newRank -eq $newRank 2> /dev/null ]
		then
			if [ $newRank -gt 0 ]
			then
				if [ $startRank -ne $newRank ]
				then
					break
				else
					echo "Error: '$newRank' must be a different than the original rank."
				fi
			else
				echo "Error: '$newRank' is invalid. Pick a non-zero positive rank."
			fi
		else
			echo "Error: '$newRank' is not a number"
		fi

		echo "Enter the rank you want to change to. (enter 'q' to quit with out changing anything)"
		read newRank
	done

	# Check to see if the user wanted to quit.
	if test $newRank = "q"
	then
		echo "Quit early was chosen."
		echo "DONE"
		break
	fi

	echo "You entered $newRank"

	#------------------------------------------------------------------------
	# find the first unassigned rank following the chosen new rank and check
	# that you can write to all the files that might be moved.
	#------------------------------------------------------------------------
	temp=$newRank
	writeAccess="true"
	while test -e "$@ - $temp.jpg"
	do
		if test -w "$@ - $temp.jpg"
		then
			temp=$(($temp+1))
		else
			echo "Error: You don't have write access to '$@ - $temp.jpg'. It is likely that you will need to change this file."
			writeAccess="false"
			break
		fi
	done
	if [ $writeAccess = "false" ]
	then
		echo "exiting script early"
		echo "ERROR"
		break
	fi
	# $temp now holds the first unassigned rank

	echo "'$temp' is the first unassigned rank following '$newRank'."

	#----------------------------------------------------------------------
	# Check to see if $startRank is one of the consecutive assigned ranks
	# following the chosen new rank. If it is then move $startRank to the
	# first unassigned rank and note that it was moved. Also, $traverse is
	# assigned to correct assigned rank after moving the start rank.
	#----------------------------------------------------------------------
	if [ $startRank -gt $newRank -a $startRank -le $temp ]
	then
		echo "moving $startRank to $temp"
		mv "$@ - $startRank.jpg"  "$@ - $temp.jpg"
		startRankMoved="true"
		echo "startRankMoved = $startRankMoved"
		traverse=$startRank
	else
		startRankMoved="false"
		traverse=$temp
	fi

	#----------------------------------------------------------------------------
	# Traverse backwards through all the consecutive assigned ranks following
	# the chosen new rank and move them up one rank number. This will make room
	# for the $startRank (or $temp if it was moved) to be placed in the new rank
	# spot.
	#----------------------------------------------------------------------------
	for (( ; traverse > newRank ; traverse-- ))
	do
		echo "moving $(($traverse-1)) to $traverse"
		mv "$@ - $(($traverse-1)).jpg"  "$@ - $traverse.jpg"
	done

	if [ $startRankMoved = "true" ]
	then
		echo "moving $temp to $newRank"
		mv "$@ - $temp.jpg"  "$@ - $newRank.jpg"
	else
		echo "moving $startRank to $newRank"
		mv "$@ - $startRank.jpg"  "$@ - $newRank.jpg"
	fi

	echo "DONE"

	break
done
)
