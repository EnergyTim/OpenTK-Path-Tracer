using System;
using System.Globalization;
using OpenTK.Mathematics;

namespace Pathtracingshadertest
{
    public static class STLreader
    {
        public static Vector3[] ParseSTLFile(string filepath)
        {
            List<Vector3> vertices = new List<Vector3>();
            string[] Lines = File.ReadAllLines(filepath);

            foreach (string Line in Lines) 
            {
                if (Line.Trim().StartsWith("vertex"))
                {
                    string[] parts = Line.Trim().Split(new[] {' '}, StringSplitOptions.RemoveEmptyEntries);

                    if (parts.Length == 4) 
                    {
                        float x = float.Parse(parts[1], CultureInfo.InvariantCulture);
                        float y = float.Parse(parts[2], CultureInfo.InvariantCulture);
                        float z = float.Parse(parts[3], CultureInfo.InvariantCulture);

                        vertices.Add(new Vector3(x, y, z));
                    }
                    else
                    {
                        throw new Exception("STL File Parsing error: parts.Length != 4");
                    }
                }
            }
            return vertices.ToArray();
        }
        public static float[] ParseSTLFilefloats(string filepath)
        {
            List<float> vertices = new List<float>();
            string[] Lines = File.ReadAllLines(filepath);

            foreach (string Line in Lines)
            {
                if (Line.Trim().StartsWith("vertex"))
                {
                    string[] parts = Line.Trim().Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);

                    if (parts.Length == 4)
                    {
                        float x = float.Parse(parts[1], CultureInfo.InvariantCulture);
                        float y = float.Parse(parts[2], CultureInfo.InvariantCulture);
                        float z = float.Parse(parts[3], CultureInfo.InvariantCulture);

                        vertices.Add(x);
                        vertices.Add(y);
                        vertices.Add(z);
                    }
                    else
                    {
                        throw new Exception("STL File Parsing error: parts.Length != 4");
                    }
                }
            }
            return vertices.ToArray();
        }
    }
}
