/*
 * The following is a dis-assembled version of SimpleRobotProgram.asm
 * starting where the "main code" begins, at the label 'center'.
 * @author Matthew Barulic
 * @date   12/1/2014
 */
while(1) {
	AC = Theta
	if(AC > 180)
		AC -= 360
	AC *= 5
	if(abs(AC) < DeadZone) {
		AC = 0
	} else {
		if(AC > 100)
			AC = 100
		if(AC < -100)
			AC = -100
	}
	// Send velocities to motors
	// Avg is the desired forward velocity
	LVel = AC + Avg
	RVel = AC - Avg
}