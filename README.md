# Resource Efficient CORDIC Neuron Architecture(RECON)

This repository contains an elementary implementation of a neuron architecture based on the CORDIC algorithm. Paper link - [paper](https://www.researchgate.net/publication/348772167_RECON_Resource-Efficient_CORDIC-Based_Neuron_Architecture) 

## Table of Contents

- [Introduction](#introduction)
- [CORDIC algorithm](#cordic-algorithm)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)


## Introduction
The paper proposes a resource-efficient Co-ordinate Rotation Digital Computer (CORDIC)-based neuron architecture (RECON) which can be configured to compute both multiply-accumulate (MAC) and non-linear activation function (AF) operations. The CORDIC-based
architecture uses linear and trigonometric relationships to realize MAC and AF operations respectively. The proposed design is synthesized and verified at 45nm technology using Cadence Virtuoso for all
physical parameters. All implementation has been realised on a 32 bit fixed point number representation(paper uses an 9 bit fixed point architecture). 

We have implemented a standard neuron architecture(without using CORDIC) for comparison with RECON architecture. Implementation of activation functions in standard neuron 
architecture is done with the help of a piecewise function(Reference will be linked).

## CORDIC Algorithm
<b>NOTE:- If you are already aware on the theory of CORDIC algorithm, skip this section <p> </b>
The COordinate Rotation DIgital Computer (CORDIC) algorithm realizes various mathematical functions by rotating vector coodinates. CORDIC algorithm works similar
to binary search, in binary search, one finds a point on the line, with the help of fixed step sizes. In CORDIC, we perform fixed step sizes on parameterised curves 
and find specific points. <br>
![Cordic Basic Diagram](recon_assets/cordic_basic_image.png)

Let's see the mathematical formulation of the algorithm, for ease of understanding, we will use a circle as the curve on which we are going to our vector for now, later
we will generalise our algorithm for other curves. 

### Functional description
Writing a vector in it's polar coordinates and rotating it by some angle alpha can be written as <br>
![Cordic math 1](recon_assets/cordic_math_1.png)
The matrix obtained in equation 1.3 is called the rotation by angle alpha matrix, we will use a short hand notation for it. <br>
![Cordic math 2](recon_assets/cordic_math_2.png)

Let's take out the cosine of the angle common from the rotation matrix thus simplifying it. 
Suppose we start from the x axis, i.e. the vector [1, 0] and we want to reach the vector at some angle thetha. From the matrix, we can figure out that one would need
the sine and cosine value of that angle to rotate the vector accordingly. Storing sine and cosine values for all such angles would be very inefficient and would defeat
the purpose of an algorithm. So we decompose our target angle into a sum of some finite step sizes. <br>
![Cordic math 3](recon_assets/cordic_math_3.png)

As made clear in the image, the step sizes are taken as such to avoid multiplication operations(multipliers are high resource consumers) and utilise bit shift 
operations. These step sizes can be stored in lookup tables for retrieval. Now combining our target angle decomposition and the above formulation, we can obtain <br>
![Cordic math 4](recon_assets/cordic_math_4.png)

Now using the psuedo rotation matrix, we can open up the matrix operations and write it in terms on system of linear equations to obtain an iteration step for the
CORDIC algorithm.
![Cordic math 5](recon_assets/cordic_math_5.png)

z is the current angle, we are supposed to repeat the iterations till z reaches zero or we reach the end of the lookup table. The decision coefficient(d) is used to
determine whether to add or subtract the step size, if the addition of the previous step size 





