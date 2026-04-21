#import <Foundation/Foundation.h>
#import "Menu.h"

@interface Menu ()

@property (assign, nonatomic) CGPoint lastMenuLocation;
@property (strong, nonatomic) UILabel *menuTitle;
@property (strong, nonatomic) UIView *header;
@property (strong, nonatomic) UIView *footer;

@end

@implementation Menu

NSUserDefaults *defaults;
UIScrollView *scrollView;
CGFloat menuWidth;
CGFloat scrollViewX;
NSString *credits;
UIColor *switchOnColor;
NSString *switchTitleFont;
UIColor *switchTitleColor;
UIColor *infoButtonColor;
NSString *menuIconBase64;
NSString *menuButtonBase64;
float scrollViewHeight = 0;
BOOL hasRestoredLastSession = false;
UIButton *menuButton;
const char *frameworkName = NULL;
UIWindow *mainWindow;

Menu *menu = [Menu alloc];
Switches *switches = [Switches alloc];

-(id)initWithTitle:(NSString *)title_ titleColor:(UIColor *)titleColor_ titleFont:(NSString *)titleFont_ credits:(NSString *)credits_ headerColor:(UIColor *)headerColor_ switchOffColor:(UIColor *)switchOffColor_ switchOnColor:(UIColor *)switchOnColor_ switchTitleFont:(NSString *)switchTitleFont_ switchTitleColor:(UIColor *)switchTitleColor_ infoButtonColor:(UIColor *)infoButtonColor_ maxVisibleSwitches:(int)maxVisibleSwitches_ menuWidth:(CGFloat )menuWidth_ menuIcon:(NSString *)menuIconBase64_ menuButton:(NSString *)menuButtonBase64_ {
    
    mainWindow = [UIApplication sharedApplication].keyWindow;
    defaults = [NSUserDefaults standardUserDefaults];

    menuWidth = menuWidth_;
    credits = credits_;
    switchTitleFont = switchTitleFont_;
    menuButtonBase64 = menuButtonBase64_;

    // --- دەستکاری ڕەنگەکان لێرەدایە ---
    UIColor *themeYellow = [UIColor colorWithRed:0.85 green:0.95 blue:0.00 alpha:1.0]; // ڕەنگە زەردەکە
    UIColor *darkBg = [UIColor colorWithRed:0.10 green:0.10 blue:0.10 alpha:0.95];   // ڕەنگی ڕەشی مێنوەکە
    
    switchOnColor = themeYellow;
    switchTitleColor = [UIColor whiteColor];
    infoButtonColor = themeYellow;

    // بنکەی سەرەکی مێنوو
    self = [super initWithFrame:CGRectMake(0,0,menuWidth_, maxVisibleSwitches_ * 50 + 50)];
    self.center = mainWindow.center;
    self.layer.opacity = 0.0f;
    self.backgroundColor = darkBg;
    self.layer.cornerRadius = 15.0f; 
    self.layer.borderWidth = 1.5f;
    self.layer.borderColor = themeYellow.CGColor;

    // بەشی سەرەوە (Header)
    self.header = [[UIView alloc]initWithFrame:CGRectMake(0, 1, menuWidth_, 50)];
    self.header.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    [self addSubview:self.header];

    // لۆگۆی ناو مێنوو
    NSData* data = [[NSData alloc] initWithBase64EncodedString:menuIconBase64_ options:0];
    UIImage* menuIconImage = [UIImage imageWithData:data];

    UIButton *menuIcon = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    menuIcon.frame = CGRectMake(5, 1, 50, 50);
    [menuIcon setBackgroundImage:menuIconImage forState:UIControlStateNormal];
    [menuIcon addTarget:self action:@selector(menuIconTapped) forControlEvents:UIControlEventTouchDown];
    [self.header addSubview:menuIcon];

    // لیستی مۆدەکان
    scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 50, menuWidth_, CGRectGetHeight(self.bounds) - 50)];
    scrollView.backgroundColor = [UIColor clearColor];
    [self addSubview:scrollView];
    scrollViewX = CGRectGetMinX(scrollView.self.bounds);

    // ناوی مێنوەکە (Hara_IOS)
    self.menuTitle = [[UILabel alloc]initWithFrame:CGRectMake(55, -2, menuWidth_ - 60, 50)];
    self.menuTitle.text = @"Hara_IOS"; // ناوەکە گۆڕدرا
    self.menuTitle.textColor = [UIColor whiteColor];
    self.menuTitle.font = [UIFont fontWithName:@"Helvetica-Bold" size:22.0f];
    self.menuTitle.textAlignment = NSTextAlignmentCenter;
    [self.header addSubview: self.menuTitle];

    // گێستچەرەکان
    UIPanGestureRecognizer *dragMenuRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(menuDragged:)];
    [self.header addGestureRecognizer:dragMenuRecognizer];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideMenu:)];
    [self.header addGestureRecognizer:tapGestureRecognizer];

    [mainWindow addSubview:self];
    [self showMenuButton];

    return self;
}

// --- کۆدە پێویستەکانی تر بۆ ئیشکردن ---
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.lastMenuLocation = CGPointMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.frame));
    [super touchesBegan:touches withEvent:event];
}

- (void)menuDragged:(UIPanGestureRecognizer *)pan {
    CGPoint newLocation = [pan translationInView:self.superview];
    self.frame = CGRectMake(self.lastMenuLocation.x + newLocation.x, self.lastMenuLocation.y + newLocation.y, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
}

- (void)hideMenu:(UITapGestureRecognizer *)tap {
    [UIView animateWithDuration:0.5 animations:^ { self.alpha = 0.0f; menuButton.alpha = 1.0f; }];
}

-(void)showMenu:(UITapGestureRecognizer *)tapGestureRecognizer {
    menuButton.alpha = 0.0f;
    [UIView animateWithDuration:0.5 animations:^ { self.alpha = 1.0f; }];
    if(!hasRestoredLastSession) { restoreLastSession(); hasRestoredLastSession = true; }
}

void restoreLastSession() {
    for(id sw in scrollView.subviews) {
        if([sw isKindOfClass:[OffsetSwitch class]]) {
            BOOL isOn = [defaults boolForKey:[sw getPreferencesKey]];
            std::vector<MemoryPatch> patches = [sw getMemoryPatches];
            for(int i = 0; i < patches.size(); i++) { if(isOn) patches[i].Modify(); else patches[i].Restore(); }
            ((OffsetSwitch*)sw).backgroundColor = isOn ? switchOnColor : [UIColor clearColor];
        }
    }
}

-(void)showMenuButton {
    NSData* data = [[NSData alloc] initWithBase64EncodedString:menuButtonBase64 options:0];
    menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    menuButton.frame = CGRectMake(100, 100, 50, 50);
    [menuButton setBackgroundImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showMenu:)];
    [menuButton addGestureRecognizer:tap];
    [menuButton addTarget:self action:@selector(buttonDragged:withEvent:) forControlEvents:UIControlEventTouchDragInside];
    [mainWindow addSubview:menuButton];
}

- (void)buttonDragged:(UIButton *)b withEvent:(UIEvent *)e {
    UITouch *t = [[e touchesForView:b] anyObject];
    CGPoint p = [t previousLocationInView:b];
    CGPoint l = [t locationInView:b];
    b.center = CGPointMake(b.center.x + (l.x - p.x), b.center.y + (l.y - p.y));
}

-(void)menuIconTapped { [self showPopup:@"Hara_IOS" description:credits]; }

-(void)showPopup:(NSString *)title_ description:(NSString *)description_ {
    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
    alert.customViewColor = [UIColor colorWithRed:0.85 green:0.95 blue:0.00 alpha:1.0];
    [alert showInfo:title_ subTitle:description_ closeButtonTitle:@"OK" duration:99999.0f];
}

- (void)addSwitchToMenu:(id)switch_ {
    [switch_ addTarget:self action:@selector(switchClicked:) forControlEvents:UIControlEventTouchDown];
    scrollViewHeight += 50;
    scrollView.contentSize = CGSizeMake(menuWidth, scrollViewHeight);
    [scrollView addSubview:switch_];
}

-(void)switchClicked:(id)switch_ {
    BOOL isOn = [defaults boolForKey:[switch_ getPreferencesKey]];
    if([switch_ isKindOfClass:[OffsetSwitch class]]) {
        std::vector<MemoryPatch> patches = [switch_ getMemoryPatches];
        for(int i = 0; i < patches.size(); i++) { if(!isOn) patches[i].Modify(); else patches[i].Restore(); }
    }
    [UIView animateWithDuration:0.3 animations:^{
        ((UIView*)switch_).backgroundColor = !isOn ? switchOnColor : [UIColor clearColor];
    }];
    [defaults setBool:!isOn forKey:[switch_ getPreferencesKey]];
}

-(void)setFrameworkName:(const char *)name_ { frameworkName = name_; }
-(const char *)getFrameworkName { return frameworkName; }
@end

@implementation OffsetSwitch
{ std::vector<MemoryPatch> memoryPatches; }
- (id)initHackNamed:(NSString *)hackName_ description:(NSString *)description_ offsets:(std::vector<uint64_t>)offsets_ bytes:(std::vector<std::string>)bytes_ {
    preferencesKey = hackName_; description = description_;
    for(int i = 0; i < offsets_.size(); i++) {
        MemoryPatch p = MemoryPatch::createWithHex([menu getFrameworkName], offsets_[i], bytes_[i]);
        if(p.isValid()) memoryPatches.push_back(p);
    }
    self = [super initWithFrame:CGRectMake(-1, scrollViewHeight, menuWidth + 2, 50)];
    self.layer.borderWidth = 0.5f;
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    switchLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, menuWidth - 60, 50)];
    switchLabel.text = hackName_;
    switchLabel.textColor = [UIColor whiteColor];
    switchLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    switchLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:switchLabel];
    return self;
}
-(NSString *)getPreferencesKey { return preferencesKey; }
- (std::vector<MemoryPatch>)getMemoryPatches { return memoryPatches; }
@end

@implementation Switches
- (void)addOffsetSwitch:(NSString *)hackName_ description:(NSString *)description_ offsets:(std::initializer_list<uint64_t>)offsets_ bytes:(std::initializer_list<std::string>)bytes_ {
    std::vector<uint64_t> ov(offsets_.begin(), offsets_.end());
    std::vector<std::string> bv(bytes_.begin(), bytes_.end());
    OffsetSwitch *sw = [[OffsetSwitch alloc]initHackNamed:hackName_ description:description_ offsets:ov bytes:bv];
    [menu addSwitchToMenu:sw];
}
@end
