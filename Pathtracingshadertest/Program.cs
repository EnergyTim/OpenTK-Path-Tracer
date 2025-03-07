using System;
using OpenTK.Windowing.Desktop;
using OpenTK.Mathematics;
using OpenTK.Windowing.Common;
using OpenTK.Graphics.OpenGL4;
using static Pathtracingshadertest.Program;
using System.Drawing;
using System.Drawing.Imaging;

namespace Pathtracingshadertest
{
    public static class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Enter model filename. For example filename.stl");
            String filename = Console.ReadLine();
            float[] Triangles = STLreader.ParseSTLFilefloats("../../../../" + filename);
            //float[] Triangles = STLreader.ParseSTLFilefloats(filename);

            Console.WriteLine("Size of model data in bytes:");
            Console.WriteLine(Triangles.Length * sizeof(float));
            Console.WriteLine("");

            Console.WriteLine("Make sure this resolution matches the one in the shader");
            Console.WriteLine("To do this change res parameter in fragment_shader.glsl");
            Console.WriteLine("");
            Console.WriteLine("Enter resolution width:");
            int w = Convert.ToInt32(Console.ReadLine());
            Console.WriteLine("Enter resolution height:");
            int h = Convert.ToInt32(Console.ReadLine());

            Console.WriteLine("Drawing");

            GameWindowSettings gws = GameWindowSettings.Default;
            NativeWindowSettings nws = NativeWindowSettings.Default;
            gws.UpdateFrequency = 0.0;

            nws.APIVersion = Version.Parse("4.1.0");
            nws.ClientSize = new Vector2i(w, h);
            nws.Title = "Path tracer";

            GameWindow gw = new GameWindow(gws, nws);

            ShaderProgram shaderprogram = new ShaderProgram() { id = 0 };
            int SSBOSTL;

            int frame = 0;

            gw.Load += () =>
            {
                shaderprogram = LoadShaderProgram("../../../../vertex_shader.glsl", "../../../../fragment_shader.glsl");
                //shaderprogram = LoadShaderProgram("vertex_shader.glsl", "fragment_shader.glsl");

                GL.GenBuffers(1, out SSBOSTL);
                GL.BindBuffer(BufferTarget.ShaderStorageBuffer, SSBOSTL);
                GL.BufferData(BufferTarget.ShaderStorageBuffer, Triangles.Length * sizeof(float), Triangles, BufferUsageHint.DynamicDraw);
                GL.BindBufferBase(BufferRangeTarget.ShaderStorageBuffer, 0, SSBOSTL);
            };

            gw.RenderFrame += (FrameEventArgs args) =>
            {
                GL.UseProgram(shaderprogram.id);

                GL.ClearColor(0f, 0f, 0f, 0f);
                GL.Clear(ClearBufferMask.ColorBufferBit);

                float[] verts = { -1f, -1f, 1f, -1f, -1f, 1f, -1f, 1f, 1f, -1f, 1f, 1f };

                int vao = GL.GenVertexArray();
                int vertices = GL.GenBuffer();
                GL.BindVertexArray(vao);
                GL.BindBuffer(BufferTarget.ArrayBuffer, vertices);
                GL.BufferData(BufferTarget.ArrayBuffer, verts.Length * sizeof(float), verts, BufferUsageHint.StaticCopy);
                GL.EnableVertexAttribArray(0);
                GL.VertexAttribPointer(0, 2, VertexAttribPointerType.Float, true, 0, 0);

                GL.DrawArrays(PrimitiveType.Triangles, 0, 6);

                GL.BindBuffer(BufferTarget.ArrayBuffer, 0);
                GL.BindVertexArray(0);
                GL.DeleteVertexArray(vao);
                GL.DeleteBuffer(vertices);

                gw.SwapBuffers();

                Console.WriteLine("FPS:" + (1f / args.Time).ToString());

                if (!Directory.Exists("output"))
                {
                    Directory.CreateDirectory("output");
                }

                frame++;

                if (frame == 10)
                {
                    SaveFrameToPng($"output/Image{DateTime.Now.Ticks}.png", gw.Size.X, gw.Size.Y); //saves 10th frame to output directory. Can be disabled
                }
            };

            gw.Run();
        }

        private static Shader LoadShader(string shaderlocation, ShaderType type)
        {
            int shaderid = GL.CreateShader(type);

            GL.ShaderSource(shaderid, File.ReadAllText(shaderlocation));
            GL.CompileShader(shaderid);

            string infolog = GL.GetShaderInfoLog(shaderid);
            if (!string.IsNullOrEmpty(infolog)) 
            {
                throw new Exception(infolog);
            }

            return new Shader() { id = shaderid };
        }

        private static ShaderProgram LoadShaderProgram(string vertexshaderlocation, string fragmentshaderlocation)
        {
            int shaderprogramid = GL.CreateProgram();

            Shader VertexShader = LoadShader(vertexshaderlocation, ShaderType.VertexShader);
            Shader FragmentShader = LoadShader(fragmentshaderlocation, ShaderType.FragmentShader);

            GL.AttachShader(shaderprogramid, VertexShader.id);
            GL.AttachShader(shaderprogramid, FragmentShader.id);
            GL.LinkProgram(shaderprogramid);
            GL.DetachShader(shaderprogramid, VertexShader.id);
            GL.DetachShader(shaderprogramid, FragmentShader.id);
            GL.DeleteShader(VertexShader.id);
            GL.DeleteShader(FragmentShader.id);

            string infolog = GL.GetProgramInfoLog(shaderprogramid);
            if (!string.IsNullOrEmpty(infolog))
            {
                throw new Exception(infolog);
            }
            return new ShaderProgram() { id = shaderprogramid };
        }

        private static void SaveFrameToPng(string filePath, int width, int height)
        {
            byte[] pixels = new byte[width * height * 4];

            GL.ReadPixels(0, 0, width, height, OpenTK.Graphics.OpenGL4.PixelFormat.Rgba, PixelType.UnsignedByte, pixels);
            Bitmap bitmap = new Bitmap(width, height, System.Drawing.Imaging.PixelFormat.Format32bppArgb);

            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    int i = (y * width + x) * 4;
                    Color color = Color.FromArgb(pixels[i + 3], pixels[i], pixels[i + 1], pixels[i + 2]);
                    bitmap.SetPixel(x, height - y - 1, color);
                }
            }
            bitmap.Save(filePath, ImageFormat.Png);
            Console.WriteLine($"Frame saved to {filePath}");
        }
        public struct Shader
        {
            public int id;
        }
        public struct ShaderProgram
        {
            public int id;
        }
    }
}