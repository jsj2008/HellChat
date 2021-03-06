//
//  HCRegisterController.m
//  HelloChat
//
//  Created by 叶根长 on 14-11-22.
//  Copyright (c) 2014年 叶根长. All rights reserved.
//

#import "HCRegisterInfoController.h"
#import "HCAppDelegate.h"
#import "HCAlertDialog.h"
#import "HCLoginUser.h"
#import "HCLoginUserTool.h"
#import "HCMainController.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+YGCCategory.h"
#import "XMPPvCardTempModule.h"
#import "XMPPvCardTemp.h"
#import "XMPPvCardAvatarModule.h"
#import "NSDate+YGCCategory.h"
@interface HCRegisterInfoController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate>
{
    
    UIButton *_btnphoto;//头像按钮
    UIButton *_btnsex;//性别
    UITextField *_txtbday;//生日
    UIActionSheet *_photosheet;//选择头像菜单
    UIActionSheet *_sexshett;//选择性别菜单
    UIDatePicker *_datepicker;//选择生日
    BOOL _didSelectPhoto;//是否设置头像
}
@end

@implementation HCRegisterInfoController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setLayout];
    _datepicker=[[UIDatePicker alloc]init];
    _datepicker.datePickerMode=UIDatePickerModeDate;
    [_datepicker addTarget:self action:@selector(dateValueChange:) forControlEvents:UIControlEventValueChanged];
    _datepicker.locale=[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    _txtbday.inputView=_datepicker;
}

#pragma mark 设置界面布局
-(void)setLayout
{
    self.title=@"个人资料(3/3)";
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(flnish)];
    //设置背景颜色
    self.view.backgroundColor=kGetColorRGB(242, 242, 230);
    
    //起始位置
    CGFloat start_y=0;
    if(IOS7_OR_LATER)
        start_y+=64;
    //注册成功提示
    UILabel *labmsg=[[UILabel alloc]initWithFrame:CGRectMake(0, start_y, kselfviewsize.width, 21)];
    labmsg.text=@"注册成功，请设置个人资料吧！";
    labmsg.textAlignment=NSTextAlignmentCenter;
    labmsg.font=kFont(13);
    [self.view addSubview:labmsg];
    
    CGFloat max_y=CGRectGetMaxY(labmsg.frame);
    //头像按钮
    _btnphoto=[UIButton buttonWithType:UIButtonTypeCustom];
    [_btnphoto setBackgroundImage:[UIImage imageNamed:@"icon_register_camera.png"] forState:UIControlStateNormal];
    _btnphoto.frame=CGRectMake((kselfviewsize.width-80)/2, max_y+5, 80, 80);
    [_btnphoto addTarget:self action:@selector(btnphotoclick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnphoto];
    
    //信息输入视图
    max_y=CGRectGetMaxY(_btnphoto.frame)+5;
    UIView *infoview=[[UIView alloc]initWithFrame:CGRectMake(0, max_y, kselfviewsize.width, 81)];
    infoview.backgroundColor=[UIColor whiteColor];
    [self.view addSubview:infoview];
    //性别
    _btnsex=[UIButton buttonWithType:UIButtonTypeCustom];
    _btnsex.frame=CGRectMake(0, 0, kselfviewsize.width, 40);
    [_btnsex setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    _btnsex.contentHorizontalAlignment=UIControlContentHorizontalAlignmentCenter;
    [_btnsex setTitle:@"性别" forState:UIControlStateNormal];
    [_btnsex addTarget:self action:@selector(btnsexclick) forControlEvents:UIControlEventTouchUpInside];
    [infoview addSubview:_btnsex];
    //分割线
    UIImageView *line=[[UIImageView alloc]initWithFrame:CGRectMake(0, 41, kselfviewsize.width, 1)];
    line.image=[UIImage imageNamed:@"line.png"];
    [infoview addSubview:line];
    //生日
    _txtbday=[[UITextField alloc]initWithFrame:CGRectMake(20, 41, kselfviewsize.width-40, 40)];
    _txtbday.inputView=_datepicker;
    _txtbday.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;
    _txtbday.textAlignment=NSTextAlignmentCenter;
    _txtbday.placeholder=@"生日";
    [infoview addSubview:_txtbday];
}


/**
 日期选择
 */
-(void)dateValueChange:(UIDatePicker *)datepicker
{
    _txtbday.text=[datepicker.date toStringWithFormater:@"yyyy-MM-dd"];
}

/**
 完成按钮点击
 */
- (void)flnish
{
    
    //验证输入
    if(_didSelectPhoto==NO)
    {
        [HCAlertDialog showDialog:@"还没有设置头像呢!"];
        return;
    }
    
    //获取性别
    NSString *sexstr=[_btnsex titleForState:UIControlStateNormal];
    
    if(!([sexstr isEqualToString:@"男"]|| [sexstr isEqualToString:@"女"]))
    {
        [HCAlertDialog showDialog:@"还没用设置性别呢!"];
        return;
    }
    
    //验证生日
    if(_txtbday.text.length<10)
    {
        [HCAlertDialog showDialog:@"还没设置生日呢!"];
        return;
    }
    
    [self updateVCard];
    
    HCLoginUser *user=[[HCLoginUser alloc]init];
    user.username=kAppdelegate.registerInfo.username;
    user.password=kAppdelegate.registerInfo.password;
    //设置当前登录账户为注册账户
    [HCLoginUserTool sharedHCLoginUserTool].loginUser=user;
    [HCLoginUserTool sharedHCLoginUserTool].userPhoto=[_btnphoto backgroundImageForState:UIControlStateNormal];
    //用户上线
    [kAppdelegate goOnline];
    
    //跳转主页面
    HCMainController *main=[[HCMainController alloc]init];
    [UIApplication sharedApplication].keyWindow.rootViewController=main;
    
    [self.view endEditing:YES];
}

/**
 保存电子名片
 */
-(void)updateVCard
{
    //获取电子名片
    XMPPvCardTemp *myvcard=kAppdelegate.xmppvCardTempModule.myvCardTemp;
    //如果本地存储没用电子名片，创建一个
    if(myvcard==nil)
        myvcard=[XMPPvCardTemp vCardTemp];
    //设置JID
    myvcard.jid=[XMPPJID jidWithString:kAppendJid(kAppdelegate.registerInfo.username)];;
    // 更新或保存电子名片
    [kAppdelegate.xmppvCardTempModule updateMyvCardTemp:myvcard];
    
    //设置昵称
    myvcard.name=kAppdelegate.registerInfo.nikiname;
    
    //设置生日
    if (_txtbday.text.length>9) {
        NSDateFormatter *formater=[[NSDateFormatter alloc]init];
        formater.dateFormat=@"yyyy-MM-dd";
        NSDate *date=[formater dateFromString:_txtbday.text];
        myvcard.bday=date;
    }
    
    //设置头像
    UIImage *img=[_btnphoto backgroundImageForState:UIControlStateNormal];
    if(img)
    {
        myvcard.photo=UIImagePNGRepresentation(img);
    }
    
    [kAppdelegate.xmppvCardTempModule updateMyvCardTemp:myvcard];
    
}

/**
 性别按钮点击
 */
- (void)btnsexclick
{
    [self.view endEditing:YES];

    if(_sexshett==nil)
    {
        _sexshett=[[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"男" otherButtonTitles:@"女",nil];
    }
    [_sexshett showInView:self.view];
}

/**
 头像按钮被点击
 */
-(void)btnphotoclick
{
    [self.view endEditing:YES];

    if(_photosheet==nil)
    {
        _photosheet=[[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"拍照" otherButtonTitles:@"打开相册", nil];
    }
    [_photosheet showInView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
    
}

/*
 *背景点击，结束编辑事件
 */
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark 设置头像按钮点击后调用事件
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet==_photosheet)
    {
        switch (buttonIndex) {
            case 0:
                [self takePhoto];
                break;
            case 1:
                [self localPhoto];
                break;
            default:
                break;
        }
    }
    else
    {
        if(buttonIndex==0)
        {
           [_btnsex setTitle:@"男" forState:UIControlStateNormal];
        }
        else if(buttonIndex==1)
        {
            [_btnsex setTitle:@"女" forState:UIControlStateNormal];
        }
    }
}

#pragma mark 打开相机拍照
-(void)takePhoto
{
    //检查相机模式是否可用
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [HCAlertDialog showDialog:@"没有可用的拍照设备"];
        return;
    }
    UIImagePickerController *imgcontroller=[[UIImagePickerController alloc]init];
    imgcontroller.sourceType=UIImagePickerControllerSourceTypeCamera;
    imgcontroller.delegate=self;
    imgcontroller.allowsEditing=YES;
    [self presentViewController:imgcontroller animated:YES completion:^{
        
    }];
}

#pragma mark 本地相册
-(void)localPhoto
{
    UIImagePickerController *imgcontroller=[[UIImagePickerController alloc]init];
    imgcontroller.sourceType=UIImagePickerControllerSourceTypePhotoLibrary;
    imgcontroller.delegate=self;
    imgcontroller.allowsEditing=YES;
    [self presentViewController:imgcontroller animated:YES completion:^{
        
    }];
}

#pragma mark 选择照片后调用的通知
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *img=info[@"UIImagePickerControllerEditedImage"];
    _didSelectPhoto=YES;
    [_btnphoto setBackgroundImage:img forState:UIControlStateNormal];
    _btnphoto.layer.masksToBounds=YES;
    _btnphoto.layer.cornerRadius=40;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
