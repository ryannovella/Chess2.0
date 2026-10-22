using System;
using System.Diagnostics;
using System.IO;

class Program
{
    static int Main(string[] args)
    {
        string baseDir = AppDomain.CurrentDomain.BaseDirectory;
        string checkpoint = Path.Combine(baseDir, "maia3-5m.pt");
        string maia3Dir = Path.Combine(baseDir, "maia3");

        string pythonExe = FindPython();
        if (string.IsNullOrEmpty(pythonExe))
        {
            Console.Error.WriteLine("Error: Python not found for Maia-3 engine.");
            return 1;
        }

        string extraArgs = args != null && args.Length > 0 ? " " + string.Join(" ", args) : "";

        // --use-uci-history WAJIB: tanpa flag ini Maia3 mengisi 8 slot riwayat
        // Chessformer dengan salinan posisi saat ini, sehingga konteks temporal
        // (rencana, pengulangan, bidak yang baru bergerak) hilang total.
        ProcessStartInfo psi = new ProcessStartInfo();
        psi.FileName = pythonExe;
        psi.Arguments = string.Format("-u -m maia3.uci --model maia3-5m --use-uci-history --checkpoint-path \"{0}\"{1}", checkpoint, extraArgs);
        psi.WorkingDirectory = baseDir;
        psi.UseShellExecute = false;
        psi.RedirectStandardInput = true;
        psi.RedirectStandardOutput = true;
        psi.RedirectStandardError = true;
        psi.CreateNoWindow = true;
        psi.EnvironmentVariables["PYTHONPATH"] = maia3Dir;
        psi.EnvironmentVariables["PYTHONUNBUFFERED"] = "1";

        Process proc = new Process();
        proc.StartInfo = psi;

        try
        {
            proc.Start();
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine("Failed to start Maia-3 python process: " + ex.Message);
            return 1;
        }

        // Forward stdout
        System.Threading.Tasks.Task.Run(() => {
            try
            {
                string line;
                while ((line = proc.StandardOutput.ReadLine()) != null)
                {
                    Console.WriteLine(line);
                }
            }
            catch {}
        });

        // Forward stderr
        System.Threading.Tasks.Task.Run(() => {
            try
            {
                string line;
                while ((line = proc.StandardError.ReadLine()) != null)
                {
                    Console.Error.WriteLine(line);
                }
            }
            catch {}
        });

        // Forward stdin
        string inputLine;
        while ((inputLine = Console.ReadLine()) != null)
        {
            try
            {
                proc.StandardInput.WriteLine(inputLine);
                proc.StandardInput.Flush();
            }
            catch
            {
                break;
            }
        }

        try
        {
            if (!proc.HasExited)
            {
                proc.StandardInput.Close();
                proc.WaitForExit(3000);
            }
        }
        catch {}

        return 0;
    }

    static string FindPython()
    {
        string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string progDir = Path.Combine(localAppData, "Programs", "Python");
        if (Directory.Exists(progDir))
        {
            foreach (string sub in Directory.GetDirectories(progDir))
            {
                string p = Path.Combine(sub, "python.exe");
                if (File.Exists(p)) return p;
            }
        }

        string pathEnv = Environment.GetEnvironmentVariable("PATH") ?? "";
        foreach (string dir in pathEnv.Split(';'))
        {
            if (string.IsNullOrWhiteSpace(dir)) continue;
            try
            {
                string p = Path.Combine(dir.Trim(), "python.exe");
                if (File.Exists(p)) return p;
            }
            catch {}
        }

        return "python";
    }
}
