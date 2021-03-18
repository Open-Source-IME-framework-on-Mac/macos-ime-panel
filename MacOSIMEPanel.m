//
//  MacOSIMEPanel.m
//  macos-ime-panel
//
//  Created by inoki on 3/18/21.
//

#import "MacOSIMEPanel.h"

@implementation MacOSIMEPanelPayload
- (id)init { return self; }
@end

@interface SimpleIMEPanel : NSView {
    NSAttributedString  *_string;
    MacOSIMEPanelPayload *m_payload;

    BOOL m_hasNextPage;
    BOOL m_hasPrevPage;
}

-(void)setAttributedString:(NSAttributedString *)str;

@property (nonatomic) MacOSIMETheme *theme;

@end

@implementation SimpleIMEPanel

-(void)setAttributedString:(NSAttributedString *)str
{
    _string = str;
    [self setNeedsDisplay:YES];
}

-(void)update:(MacOSIMEPanelPayload *)payload
{
    m_payload = payload;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
    if (!m_payload)
        return;

    [[NSColor clearColor] set];
    NSRectFill([self bounds]);

    // Draw background
    if ([_theme panelBackgroundImage] != nil) {
        NSImage *image = [_theme panelBackgroundImage];
        [image setCapInsets:NSEdgeInsetsMake([_theme panelBackgroundMarginLT].x,
                                             [_theme panelBackgroundMarginLT].y,
                                             [_theme panelBackgroundMarginRB].y,
                                             [_theme panelBackgroundMarginRB].x)];
        // TODO: Set transparency
        [image drawInRect:rect fromRect:NSZeroRect
                operation:NSCompositingOperationSourceOver fraction:1];
    }

    // Draw pager
    NSRect nextRect = rect;
    if ([_theme panelNextPageImage] != nil ) {
        NSImage *image = [_theme panelNextPageImage];
        nextRect.size = [image size];
        nextRect.origin.x = rect.origin.x + rect.size.width - nextRect.size.width;
        nextRect.origin.y = rect.origin.y + [_theme panelContentMarginRB].y;
        if (m_hasNextPage) {
            [image drawInRect:nextRect fromRect:NSZeroRect
                    operation:NSCompositingOperationSourceOver fraction:1];
        } else {
            [image drawInRect:nextRect fromRect:NSZeroRect
                    operation:NSCompositingOperationSourceOver fraction:0.3];
        }
    }
    if ([_theme panelPrevPageImage] != nil) {
        NSImage *image = [_theme panelPrevPageImage];
        NSRect prevRect = rect;
        prevRect.size = [image size];
        prevRect.origin.x = nextRect.origin.x - prevRect.size.width;
        prevRect.origin.y = nextRect.origin.y;
        if (m_hasPrevPage) {
            [image drawInRect:prevRect fromRect:NSZeroRect
                    operation:NSCompositingOperationSourceOver fraction:1];
        } else {
            [image drawInRect:prevRect fromRect:NSZeroRect
                    operation:NSCompositingOperationSourceOver fraction:0.3];
        }
        // TODO: Actions
    }

    // Init normal font attr
    NSMutableDictionary *_attr = [[NSMutableDictionary alloc] init];
    [_attr setObject:[_theme panelNormalColor] forKey:NSForegroundColorAttributeName];
    [_attr setObject:[_theme panelFont] forKey:NSFontAttributeName];

    // TODO: Draw layouts (aux, preedit)
    NSAttributedString *auxTextString = [[NSAttributedString alloc] initWithString:[m_payload auxiliaryText] attributes:_attr];
    NSRect auxTextRect;
    auxTextRect.origin.x = rect.origin.x + [_theme panelContentMarginLT].x + [_theme panelTextMarginLT].x;
    auxTextRect.origin.y = rect.origin.y + rect.size.height - [_theme panelContentMarginLT].y - [_theme panelTextMarginLT].y - 20;
    auxTextRect.size = [auxTextString size];
    [auxTextString drawInRect:auxTextRect];

    // TODO: Draw highlight
    CGFloat fullWidth = rect.origin.x + [_theme panelContentMarginLT].x;
    for (NSUInteger i = 0; i < [[m_payload candidates] count]; i++) {
        CGFloat x, y;
        NSRect candidateRect;
        NSString *candidate = [[m_payload candidates] objectAtIndex:i];
        // NSAttributedString *candidateString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu.%@", i + 1, candidate] attributes:_attr];
        NSAttributedString *candidateString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", candidate] attributes:_attr];
        x = fullWidth + [_theme panelTextMarginLT].x;
        y = rect.origin.y + [_theme panelTextMarginRB].y;
        candidateRect.origin.x = x;
        candidateRect.origin.y = y;
        candidateRect.size = [candidateString size];
        [candidateString drawInRect:candidateRect];
        fullWidth = x + candidateRect.size.width + [_theme panelTextMarginRB].x;
    }
}

@end


@implementation MacOSIMEPanel {
    NSWindow *m_window;
    NSView *m_view;

    MacOSIMEPanelPayload *m_payload;
    // TODO: replace them
    NSArray *m_candidates;
    NSString *m_auxText;
    NSString *m_preeditText;

    // Temp
    NSMutableAttributedString *m_string;

    BOOL m_hasNextPage;
    BOOL m_hasPrevPage;
}

- (id)init {
    _theme = [[MacOSIMETheme alloc] initWithThemeName:@"Default"];
    m_window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,0,0)
                                           styleMask:NSWindowStyleMaskBorderless
                                             backing:NSBackingStoreBuffered
                                               defer:NO];
    [m_window setAlphaValue:1.0];
    [m_window setLevel:NSScreenSaverWindowLevel + 1];
    [m_window setHasShadow:YES];
    [m_window setOpaque:NO];
    m_view = [[SimpleIMEPanel alloc] initWithFrame:[[m_window contentView] frame]];
    [m_window setContentView:m_view];

    m_hasNextPage = NO;
    m_hasPrevPage = NO;

    m_auxText = nil;
    m_preeditText = nil;

    return self;
}

- (void)hide {
    _visible = NO;
    [m_window orderOut:self];
}

- (void)update:(MacOSIMEPanelPayload *)payload {
    // TODO: do sth with DPI

    // TODO: Prepare auxiliary data, preedit data and candidate
    // auxiliary text
    m_auxText = @"TestTestTestPinyin|";
    // candidate
    m_candidates = @[
        @"Test", @"Testg", @"Testq", @"Testp", @"Test4"
    ];
    [payload setAuxiliaryText:m_auxText];
    [payload setCandidates:m_candidates];
    NSFont *_font = [NSFont systemFontOfSize:16];
    NSColor *_hlColor = [NSColor blueColor];

    NSMutableDictionary *_attr = [[NSMutableDictionary alloc] init];
    // [_attr setObject:_fgColor forKey:NSForegroundColorAttributeName];
    [_attr setObject:_font forKey:NSFontAttributeName];
    m_string = [[NSMutableAttributedString alloc] init];
    for (NSUInteger i = 0; i < [m_candidates count]; i++) {
        NSString *str = [NSString stringWithFormat:@"%lu.%@ ", i+1, [m_candidates objectAtIndex:i]];
        NSAttributedString *astr = [[NSAttributedString alloc] initWithString:str attributes:_attr];
        [m_string appendAttributedString:astr];

        if (i==0)
            [m_string addAttribute:NSForegroundColorAttributeName
                    value:_hlColor
                    range:NSMakeRange(0, [str length])];
    }
    _size = [m_string size];
    _size.height += (20 + [_theme panelContentMarginRB].y + [_theme panelContentMarginLT].y
                     + [_theme panelTextMarginRB].y + [_theme panelTextMarginLT].y);
    _size.width += ([_theme panelContentMarginRB].x + [_theme panelContentMarginLT].x
                    + [_theme panelTextMarginRB].x + [_theme panelTextMarginLT].x);
    m_payload = payload;
    if ([m_candidates count] > 0) {
        _visible = YES;
    }

    // Update position
    [self updatePosition];

    // Paint and render
    [self paint];
    [self render];
}

- (void)updatePosition {
    if (!_visible) {
        // Do nothing
        return;
    }

    NSRect winRect;
    NSRect cursorRect = NSMakeRect(100, 100, 800, 600);
    winRect.origin.x = cursorRect.origin.x + 2;
    winRect.origin.y = cursorRect.origin.y - winRect.size.height - 20;
    winRect.size = _size;

    // Find a screen
    NSRect screenRect = [[NSScreen mainScreen] frame];
    NSArray *screens =[NSScreen screens];
    NSUInteger numOfScreens = [screens count];

    if (numOfScreens > 1) {
        // Find a proper screen with curosr
        BOOL screenFound = NO;
        for (NSUInteger screenIndex = 0; screenIndex < numOfScreens; screenIndex++) {
            NSScreen *screen = [screens objectAtIndex:screenIndex];
            NSRect rect = [screen frame];
            if (NSPointInRect (cursorRect.origin, rect)) {
                screenRect = rect;
                screenFound = YES;
                break;
            }
        }

        // Find a proper screen with mouse position
        HIPoint pos;
        HIGetMousePosition (kHICoordSpaceScreenPixel, NULL, &pos);
        NSPoint mousePosition;
        mousePosition.x = pos.x;
        mousePosition.y = screenRect.size.height - pos.y;

        for (NSUInteger screenIndex = 0; screenIndex < numOfScreens; screenIndex++) {
            NSScreen *screen = [screens objectAtIndex:screenIndex];
            NSRect rect = [screen frame];
            if (NSPointInRect(mousePosition, rect)) {
                screenRect = rect;
                screenFound = YES;
            }
        }

        if (!screenFound) {
            // No proper screen after many tries
            return;
        }
    }

    // Regulate position
    CGFloat minX = NSMinX(screenRect);
    CGFloat maxX = NSMaxX(screenRect);
    CGFloat minY = NSMinY(screenRect);

    if (winRect.origin.x < minX) {
        winRect.origin.x = minX;
    }

    if (winRect.origin.x + winRect.size.width > maxX) {
        winRect.origin.x = maxX - winRect.size.width;
    }

    if (winRect.origin.y < minY) {
        // FIXME: may have bug
        winRect.origin.y = cursorRect.origin.y > minY ?
            cursorRect.origin.y + cursorRect.size.height + 20:
            minY;
    }

    // Update size
    if (winRect.size.width != _size.width || winRect.size.height != _size.height) {
        _size = winRect.size;
    }

    // Set the frame
    [m_window setFrame:winRect display:NO animate:NO];
}

- (void)wheel:(BOOL)isUp {
}

- (bool)hoverAt:(NSPoint)point {
    return YES;
}

- (bool)clickAt:(NSPoint)point {
    return YES;
}

- (void)resize:(NSSize)newSize {
    // TODO
    _size = newSize;
}

/* private methods */
- (void)paint {
    // Set theme
    if (_theme != [(SimpleIMEPanel *)m_view theme]) {
        [(SimpleIMEPanel *)m_view setTheme:_theme];
    }

    // Set auxiliary data, preedit data and candidate
    [(SimpleIMEPanel *)m_view update:m_payload];
}

- (void)render {
    // Display and put it in front if necessary
    if (_visible) {
        [m_window display];
        [m_window orderFront:nil];
    }
}

@end
