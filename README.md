# OpenTK Path Tracer

## This is a path tracer built using C#, OpenTK and GLSL.

### It uses backwards ray tracing, Lambertian BRDF.

### It saves 10th frame to the output directory.

## Instructions:
1. 3D models should be exported as ASCII STL files.
2. 3D models should be in the same folder as fragment_shader.glsl and vertex_shader.glsl
3. Material, resolution, sky parameters, ray depth and sample rate can be adjusted in fragment_shader.glsl
4. After launch the program will request filename. Type your required file's filename including its format (ex. testcube.stl)
5. After this enter resolution witdh and height. Make sure they match the ones in the fragment_shader.glsl (res parameter)
6. After that the rendering will start. A window containing real-time render will open.
7. The 10th rendered frame will be saved to the output directory. It should be located whre the .exe file is.

## Output directory is created when the program is launched for the first time.

## Filepaths in the program.cs are relative to the .exe file. If the position of the fragment_shader.glsl etc. changes, filepaths should be edited.

![Image638769775473101389](https://github.com/user-attachments/assets/98117379-a079-4ae6-a468-b8f1822ffe89)
