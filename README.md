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

## Project structure
- CORDIC
  - Matlab
  - Verilog
- activation_function
- multiply-accumulate
- traditional_neuron_with_mac_maf
- CORDIC_Neuron.ipynb
- Normal_Neuron_.ipynb

## Usage

### CORDIC architecture

The CORDIC directory contains two subdirectories, namely Matlab and Verilog. Matlab only has code for test case generation for activation function and division. 
Verilog directory contains the actual code for the architecture, to run it directly using iverilog, use the commands

```bash
iverilog cordic_neuron.v cordic_neuron_tb.v cordictanh.v cordicdiv.v cordic_mac.v atanh_LOOKUP.v
vvp ./a.out
```
The other verilog files are testbenches for testing the functionalities for individual modules. For top module, the given test cases in cordic_neuron_tb.v are pretty
basic and do not provide rigorous testing for the architecture, one can manipulate the matlab code a little to get files for rigorous testing of the module.
Though rigorous testing on individual modules is a confident indicator that the whole architecture would be able to handle rigorous testing at the same level.



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
determine whether to add or subtract the step size, if the addition of the previous step size.

### Rotation and Vector mode

CORDIC algorithm can be used in two modes, namely rotation and vector modes. In rotation mode, we take a vector and rotate it by some angle z, converging our x and y
coordinates of the vector to parameterised coordinates of the curve(Polar in case of circles, Hyperbolic in case of Hyperbola, cartesian in case of line etc). 
![Cordic math 6](recon_assets/cordic_math_6.png)

In vector mode, we want to find the phase of a vector that is on some curve by rotating the vector towards x axis along the curve. 
![Cordic math 7](recon_assets/cordic_math_7.png)

### Generalised CORDIC algorithm

We can consider our derivation procedure for CORDIC along a parametrised curve rather than a fixed one now <br>
![Cordic math 8](recon_assets/cordic_math_8.png)
![Cordic math 9](recon_assets/cordic_math_9.png)

Note that scaling factors for different values of m will also be different. For most applications, we consider only three values of m, m = 0, 1, -1 as they represent line, circle and hyperbola. Their results can be seen below. <br>
![Cordic math 10](recon_assets/cordic_math_10.png)

Some further minor details have been taken care of while doing verilog implementations(eg - hyperbolic convergence), they have been mentioned in the comments
in the code, mathematical details on those are high order and irrelevant for the scope of this project.







