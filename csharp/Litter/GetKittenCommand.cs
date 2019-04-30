using PSFramework.Commands;
using PSFramework.Message;
using System;
using System.Management.Automation;


namespace Litter
{
    [Cmdlet("Get", "Kitten")]
    public class GetKittenCommand : PSFCmdlet
    {
        [Parameter(Mandatory = true)]
        public string Kitten;

        [Parameter(Mandatory = true)]
        public string Slave;

        protected override void ProcessRecord()
        {
            WriteMessage(String.Format("{0} is petting {1}", Slave, Kitten), MessageLevel.Host, "Get-Kitten", "Litter", "GetKittenCommand.cs", 19, null, Kitten);

            WriteLocalizedMessage("Kittens.ObedientSlave", new object[] { Slave, Kitten }, MessageLevel.Critical, "Get-Kitten", "Litter", "GetKittenCommand.cs", 21, null, Kitten);
        }
    }
}
