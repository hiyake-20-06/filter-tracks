using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("Tool Filter")]
[assembly: AssemblyProduct("Tool Filter")]
[assembly: AssemblyDescription("Loc dung luong o C: - chi doc, khong xoa")]
[assembly: AssemblyCompany("Tool Filter")]
[assembly: AssemblyCopyright("MIT License")]

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        bool created;
        using (var mutex = new Mutex(true, "ToolFilter_SingleInstance_v1", out created))
        {
            if (!created)
            {
                MessageBox.Show("Tool Filter đang chạy rồi.", "Tool Filter",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            string dir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            string script = Path.Combine(dir, @"resources\Tool-Filter.ps1");
            if (!File.Exists(script))
                script = Path.Combine(dir, "Tool-Filter.ps1");

            if (!File.Exists(script))
            {
                MessageBox.Show(
                    "Không tìm thấy resources\\Tool-Filter.ps1.\n\n" +
                    "Hãy giải nén đầy đủ thư mục ứng dụng (đừng chỉ lấy mỗi file .exe).",
                    "Tool Filter - Thiếu tệp", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            string ps = Path.Combine(Environment.SystemDirectory, @"WindowsPowerShell\v1.0\powershell.exe");
            if (!File.Exists(ps)) ps = "powershell.exe";

            var psi = new ProcessStartInfo
            {
                FileName = ps,
                Arguments = "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + script + "\"",
                WorkingDirectory = dir,
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };

            try
            {
                using (var p = Process.Start(psi))
                {
                    if (p == null) throw new InvalidOperationException("Không tạo được tiến trình PowerShell.");
                    p.WaitForExit();
                    if (p.ExitCode != 0)
                    {
                        MessageBox.Show(
                            "Ứng dụng kết thúc với mã lỗi " + p.ExitCode + ".\n\n" +
                            "Chạy Troubleshoot.cmd để xem chi tiết lỗi.",
                            "Tool Filter - Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "Không khởi động được PowerShell.\n\n" + ex.Message,
                    "Tool Filter - Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
