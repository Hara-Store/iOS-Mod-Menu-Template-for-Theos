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
    
    // --- ڕەنگە نوێیەکان بەپێی وێنەکە ---
    // ڕەنگی زەردی دیزاینەکە (KTM Style)
    UIColor *themeYellow = [UIColor colorWithRed:0.85 green:0.95 blue:0.00 alpha:1.0];
    // ڕەنگی ڕەشی باکگراوند
    UIColor *darkBg = [UIColor colorWithRed:0.10 green:0.10 blue:0.10 alpha:0.95];
    
    switchOnColor = themeYellow;
    switchTitleColor = [UIColor whiteColor];
    infoButtonColor = themeYellow;

    self = [super initWithFrame:CGRectMake(0,0,menuWidth_, maxVisibleSwitches_ * 50 + 50)];
    self.center = mainWindow.center;
    self.layer.opacity = 0.0f;
    self.backgroundColor = darkBg;
    self.layer.cornerRadius = 15.0f; // لێوارەکان خڕ دەکات
    self.layer.borderWidth = 1.5f;
    self.layer.borderColor = themeYellow.CGColor; // چوارچێوە زەردەکە

    // Header
    self.header = [[UIView alloc]initWithFrame:CGRectMake(0, 0, menuWidth_, 45)];
    self.header.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    [self addSubview:self.header];

    // Menu Title
    self.menuTitle = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, menuWidth_, 45)];
    self.menuTitle.text = title_;
    self.menuTitle.textColor = [UIColor whiteColor];
    self.menuTitle.font = [UIFont fontWithName:@"Helvetica-Bold" size:18.0f];
    self.menuTitle.textAlignment = NSTextAlignmentCenter;
    [self.header addSubview: self.menuTitle];

    // ScrollView (لیستی مۆدەکان)
    scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 45, menuWidth_, CGRectGetHeight(self.bounds) - 45)];
    scrollView.backgroundColor = [UIColor clearColor];
    [self addSubview:scrollView];
    scrollViewX = CGRectGetMinX(scrollView.self.bounds);

    // Gestures
    UIPanGestureRecognizer *dragMenuRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(menuDragged:)];
    [self.header addGestureRecognizer:dragMenuRecognizer];
    
    UITapGestureRecognizer *hideGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideMenu:)];
    [self.header addGestureRecognizer:hideGesture];

    [mainWindow addSubview:self];
    [self showMenuButton];

    return self;
}

// --- لێرە بەدواوە کۆدە ستانداردەکانە بۆ ئەوەی ئیرۆر نەدات ---
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.lastMenuLocation = CGPointMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.frame));
    [super touchesBegan:touches withEvent:event];
}

- (void)menuDragged:(UIPanGestureRecognizer *)pan {
    CGPoint newLocation = [pan translationInView:self.superview];
    self.frame = CGRectMake(self.lastMenuLocation.x + newLocation.x, self.lastMenuLocation.y + newLocation.y, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
}

- (void)hideMenu:(UITapGestureRecognizer *)tap {
    [UIView animateWithDuration:0.3 animations:^{ self.alpha = 0.0f; menuButton.alpha = 1.0f; }];
}

-(void)showMenu:(UITapGestureRecognizer *)tap {
    menuButton.alpha = 0.0f;
    [UIView animateWithDuration:0.3 animations:^{ self.alpha = 1.0f; }];
    if(!hasRestoredLastSession) { restoreLastSession(); hasRestoredLastSession = true; }
}

void restoreLastSession() {
    for(id sw in scrollView.subviews) {
        if([sw isKindOfClass:[OffsetSwitch class]]) {
            BOOL isOn = [defaults boolForKey:[sw getPreferencesKey]];
            std::vector<MemoryPatch> patches = [sw getMemoryPatches];
            for(int i=0; i<patches.size(); i++) { if(isOn) patches[i].Modify(); else patches[i].Restore(); }
            ((OffsetSwitch*)sw).backgroundColor = isOn ? [UIColor colorWithRed:0.85 green:0.95 blue:0.00 alpha:0.3] : [UIColor clearColor];
        }
    }
}

-(void)showMenuButton {
    NSData* data = [[NSData alloc] initWithBase64EncodedString:menuButtonBase64 options:0];
    menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    menuButton.frame = CGRectMake(100, 100, 55, 55);
    [menuButton setBackgroundImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
    menuButton.layer.cornerRadius = 27.5f; // بازنەیی دەکات
    menuButton.clipsToBounds = YES;
    
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

-(void)menuIconTapped { [self showPopup:self.menuTitle.text description:credits]; }

-(void)showPopup:(NSString *)t description:(NSString *)d {
    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
    alert.customViewColor = [UIColor colorWithRed:0.85 green:0.95 blue:0.00 alpha:1.0];
    [alert showInfo:t subTitle:d closeButtonTitle:@"OK" duration:99999.0f];
}

- (void)addSwitchToMenu:(id)sw {
    [sw addTarget:self action:@selector(switchClicked:) forControlEvents:UIControlEventTouchDown];
    scrollViewHeight += 50;
    scrollView.contentSize = CGSizeMake(menuWidth, scrollViewHeight);
    [scrollView addSubview:sw];
}

-(void)switchClicked:(id)sw {
    BOOL isOn = [defaults boolForKey:[sw getPreferencesKey]];
    if([sw isKindOfClass:[OffsetSwitch class]]) {
        std::vector<MemoryPatch> patches = [sw getMemoryPatches];
        for(int i=0; i<patches.size(); i++) { if(!isOn) patches[i].Modify(); else patches[i].Restore(); }
    }
    [UIView animateWithDuration:0.3 animations:^{
        ((UIView*)sw).backgroundColor = !isOn ? [UIColor colorWithRed:0.85 green:0.95 blue:0.00 alpha:0.3] : [UIColor clearColor];
    }];
    [defaults setBool:!isOn forKey:[sw getPreferencesKey]];
}

-(void)setFrameworkName:(const char *)n { frameworkName = n; }
-(const char *)getFrameworkName { return frameworkName; }
@end

@implementation OffsetSwitch
{ std::vector<MemoryPatch> memoryPatches; }
- (id)initHackNamed:(NSString *)h description:(NSString *)d offsets:(std::vector<uint64_t>)o bytes:(std::vector<std::string>)b {
    preferencesKey = h; description = d;
    for(int i=0; i<o.size(); i++) {
        MemoryPatch p = MemoryPatch::createWithHex([menu getFrameworkName], o[i], b[i]);
        if(p.isValid()) memoryPatches.push_back(p);
    }
    self = [super initWithFrame:CGRectMake(5, scrollViewHeight, menuWidth-10, 45)];
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = [UIColor colorWithRed:0.85 green:0.95 blue:0.00 alpha:0.5].CGColor;
    self.layer.cornerRadius = 8.0f;
    
    switchLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, menuWidth-40, 45)];
    switchLabel.text = h;
    switchLabel.textColor = [UIColor whiteColor];
    switchLabel.font = [UIFont fontWithName:@"Helvetica" size:15];
    [self addSubview:switchLabel];
    return self;
}
-(NSString *)getPreferencesKey { return preferencesKey; }
- (std::vector<MemoryPatch>)getMemoryPatches { return memoryPatches; }
@end

@implementation Switches
-(void)addOffsetSwitch:(NSString *)h description:(NSString *)d offsets:(std::initializer_list<uint64_t>)o bytes:(std::initializer_list<std::string>)b {
    std::vector<uint64_t> ov(o.begin(), o.end());
    std::vector<std::string> bv(b.begin(), b.end());
    OffsetSwitch *sw = [[OffsetSwitch alloc]initHackNamed:h description:d offsets:ov bytes:bv];
    [menu addSwitchToMenu:sw];
}
@end
