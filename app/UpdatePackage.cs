using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Reflection;
namespace StadiaStudio {
    public static class UpdatePackage {
        public static void Verify(string directory){
            Directory.CreateDirectory(directory);string root=Path.Combine(directory,"installed"),backups=Path.Combine(directory,"backups");SetupEntry.Extract(root);
            string marker=Path.Combine(root,"Driver.sha256"),expected=File.ReadAllText(marker),doc=Path.Combine(root,"USO.md"),original=File.ReadAllText(doc);
            string sentinel=Path.Combine(root,"user-profile.json");File.WriteAllText(sentinel,"keep");
            File.WriteAllText(doc,"old guide");bool failed=false;
            try{Apply(root,()=>{throw new IOException("Injected registration failure");},backups);}catch(IOException){failed=true;}
            if(!failed||File.ReadAllText(doc)!="old guide"||File.ReadAllText(sentinel)!="keep")throw new Exception("Update rollback failed.");
            File.WriteAllText(marker,"incompatible");failed=false;try{Apply(root,()=>{},backups);}catch(InvalidOperationException){failed=true;}
            if(!failed||File.ReadAllText(doc)!="old guide")throw new Exception("Incompatible driver update accepted.");
            File.WriteAllText(marker,expected);Apply(root,()=>{},backups);
            if(File.ReadAllText(doc)!=original||File.ReadAllText(sentinel)!="keep")throw new Exception("App update failed or profile changed.");
            File.WriteAllText(Path.Combine(directory,"result.txt"),"PASS: app-only update, incompatible driver refusal, rollback on failure, user files preserved, no driver installation or registry changes during tests.");
        }
        public static void Apply(string root,Action register=null,string backupBase=null){
            string stage=Path.Combine(Path.GetTempPath(),"StadiaLink-update-"+Guid.NewGuid().ToString("N"));
            string backup=Path.Combine(backupBase??Path.Combine(ProfileLibrary.DirectoryPath,"update-backup"),Guid.NewGuid().ToString("N"));
            var changed=new List<string>();var existed=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            Directory.CreateDirectory(stage);
            try{
                SetupEntry.Extract(stage);
                string installed=Path.Combine(root,"StadiaLink.exe"),marker=Path.Combine(root,"Driver.sha256");
                string expected=Path.Combine(stage,"Driver.sha256");
                if(!File.Exists(installed)||!File.Exists(marker)||!File.Exists(expected)||
                   File.ReadAllText(marker).Trim()!=File.ReadAllText(expected).Trim())throw new InvalidOperationException("Esta actualización requiere el instalador completo.");
                Version installedVersion;
                if(Version.TryParse(FileVersionInfo.GetVersionInfo(installed).FileVersion,out installedVersion)&&installedVersion>Assembly.GetExecutingAssembly().GetName().Version)throw new InvalidOperationException("Hay una versión más reciente instalada.");
                Directory.CreateDirectory(backup);
                foreach(string source in Directory.GetFiles(stage)){
                    string name=Path.GetFileName(source),target=Path.Combine(root,name);
                    if(File.Exists(target)){File.Copy(target,Path.Combine(backup,name),true);existed.Add(name);}
                    changed.Add(name);File.Copy(source,target,true);
                }
                if(register==null)InstallerActions.RegisterApp();else register();
            }catch{
                foreach(string name in changed){string target=Path.Combine(root,name);if(existed.Contains(name))File.Copy(Path.Combine(backup,name),target,true);else if(File.Exists(target))File.Delete(target);}
                throw;
            }finally{if(Directory.Exists(stage))Directory.Delete(stage,true);}
        }
    }
}
