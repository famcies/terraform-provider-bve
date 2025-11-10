package rootmount

import (
	pveSDK "github.com/Telmate/proxmox-api-go/proxmox"
	"github.com/famcies/terraform-provider-bve/bve/Internal/helper/size"
	"github.com/famcies/terraform-provider-bve/bve/Internal/resource/guest/lxc/_sub/acl"
	"github.com/famcies/terraform-provider-bve/bve/Internal/util"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func SDK(privilidged bool, d *schema.ResourceData) *pveSDK.LxcBootMount {
	v, ok := d.GetOk(Root)
	if !ok {
		return nil
	}
	vv, ok := v.([]any)
	if ok && len(vv) != 1 {
		return nil
	}
	settings, ok := vv[0].(map[string]any)
	if !ok {
		return nil
	}
	var quota *bool
	if privilidged {
		quota = util.Pointer(settings[schemaQuota].(bool))
	}
	return &pveSDK.LxcBootMount{
		ACL:             acl.SDK(settings[schemaACL].(string)),
		Options:         sdkOptions(settings[schemaOptions]),
		Quota:           quota,
		Replicate:       util.Pointer(settings[schemaReplicate].(bool)),
		SizeInKibibytes: util.Pointer(pveSDK.LxcMountSize(size.Parse_Unsafe(settings[schemaSize].(string)))),
		Storage:         util.Pointer(settings[schemaStorage].(string))}
}

func sdkOptions(schema any) *pveSDK.LxcBootMountOptions {
	v, ok := schema.([]any)
	if ok && len(v) != 1 {
		return nil
	}
	settings, ok := v[0].(map[string]any)
	if !ok {
		return nil
	}
	return &pveSDK.LxcBootMountOptions{
		Discard:  util.Pointer(settings[schemaDiscard].(bool)),
		LazyTime: util.Pointer(settings[schemaLazyTime].(bool)),
		NoATime:  util.Pointer(settings[schemaNoATime].(bool)),
		NoSuid:   util.Pointer(settings[schemaNoSuid].(bool))}
}
