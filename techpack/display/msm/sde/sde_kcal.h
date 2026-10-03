/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Copyright (c) 2026, The Linux Foundation. All rights reserved.
 * KCAL - Advanced Color Control for Qualcomm SDE DSPP
 */

#ifndef _SDE_KCAL_H_
#define _SDE_KCAL_H_

#include <drm/drm_crtc.h>

void sde_kcal_apply(struct drm_crtc *crtc);
void sde_kcal_notify_dirty(void);

#endif /* _SDE_KCAL_H_ */
