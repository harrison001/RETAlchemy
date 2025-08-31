// retalchemy_kmod.c — Minimal vulnerable kernel module (x86-64, Linux)
// PoC for educational research ONLY. Build/run inside an isolated VM.
//
// Device: /dev/retalchemy  (misc char dev, 0666)
// Vulnerability: write() copies user 'count' bytes into a 64-byte on-stack buffer
//                without bounds checking → kernel stack overflow.
//
// Suggested lab kernel: disable KASLR/SMEP/SMAP; enable CONFIG_KALLSYMS=y
// Compile flags here also disable stack protector and keep frame pointers to ease analysis.
#include <linux/module.h>
#include <linux/miscdevice.h>
#include <linux/fs.h>
#include <linux/uaccess.h>

#define DRV_NAME "retalchemy"
#define BUF_SZ   64

static ssize_t ra_write(struct file *f, const char __user *ubuf, size_t count, loff_t *ppos)
{
    char local[BUF_SZ]; // on-stack buffer (intentional for PoC)
    // *** VULN: NO bounds check. If count > 64, this overflows the kernel stack. ***
    if (copy_from_user(local, ubuf, count))
        return -EFAULT;

    // Touch 'local' so compiler keeps it
    if (count && local[0] == 0xFF)
        pr_info(DRV_NAME ": marker byte seen\n");

    pr_info(DRV_NAME ": wrote %zu bytes (no bounds check!)\n", count);
    return count;
}

static const struct file_operations ra_fops = {
    .owner = THIS_MODULE,
    .write = ra_write,
};

static struct miscdevice ra_dev = {
    .minor = MISC_DYNAMIC_MINOR,
    .name  = DRV_NAME,
    .fops  = &ra_fops,
    .mode  = 0666,
};

static int __init ra_init(void)
{
    int ret = misc_register(&ra_dev);
    if (ret) {
        pr_err(DRV_NAME ": misc_register failed: %d\n", ret);
        return ret;
    }
    pr_info(DRV_NAME ": loaded. write() to /dev/%s to trigger overflow\n", DRV_NAME);
    return 0;
}

static void __exit ra_exit(void)
{
    misc_deregister(&ra_dev);
    pr_info(DRV_NAME ": unloaded\n");
}

module_init(ra_init);
module_exit(ra_exit);

MODULE_AUTHOR("RETAlchemy");
MODULE_DESCRIPTION("RETAlchemy vulnerable misc device (stack overflow in write)");
MODULE_LICENSE("GPL");

