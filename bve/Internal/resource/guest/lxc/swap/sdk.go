package swap

import (
	pveSDK "github.com/Telmate/proxmox-api-go/proxmox"
	"github.com/famcies/terraform-provider-bve/bve/Internal/util"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func SDK(d *schema.ResourceData) *pveSDK.LxcSwap {
	return util.Pointer(pveSDK.LxcSwap(d.Get(Root).(int)))
}
