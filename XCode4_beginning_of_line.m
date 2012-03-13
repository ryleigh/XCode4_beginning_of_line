#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP original_doCommandBySelector = nil;

@interface XCode4_beginning_of_line : NSObject
@end

@implementation XCode4_beginning_of_line
static void doCommandBySelector( id self_, SEL _cmd, SEL selector )
{
    /* CMD+LEFT: moves to beginning of text on line*/
    if (selector == @selector(moveToBeginningOfLine:) ||
        selector == @selector(moveToLeftEndOfLine:))
    {
        NSTextView *self = (NSTextView *)self_;
        NSString *text = self.string;
        NSRange selectedRange = self.selectedRange;
        NSRange lineRange = [text lineRangeForRange:selectedRange];
        if (lineRange.length != 0)
        {
            NSString *line = [text substringWithRange:lineRange];
            NSRange codeStartRange = [line rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
            if (codeStartRange.location != NSNotFound)
            {
                NSUInteger caretLocation = selectedRange.location - lineRange.location;
                if (caretLocation > codeStartRange.location || caretLocation == 0)
                {
                    [self setSelectedRange:NSMakeRange(lineRange.location + codeStartRange.location, 0)];
                    return;
                }
            }
        }
    }
    /* SHIFT+CMD+LEFT: highlights to beginning of text on line */
    else if(selector == @selector(moveToBeginningOfLineAndModifySelection:) ||
            selector == @selector(moveToLeftEndOfLineAndModifySelection:))
    {
        NSTextView *self = (NSTextView *)self_;
        NSString *text = self.string;
        NSRange selectedRange = self.selectedRange;
        NSRange lineRange = [text lineRangeForRange:selectedRange];
        if (lineRange.length != 0)
        {
            NSString *line = [text substringWithRange:lineRange];
            NSRange codeStartRange = [line rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
            
            if (codeStartRange.location != NSNotFound)
            {
                NSUInteger caretLocation = selectedRange.location - lineRange.location;
                if (caretLocation > codeStartRange.location)
                {
                    [self setSelectedRange:NSMakeRange(lineRange.location + codeStartRange.location, (caretLocation - codeStartRange.location))];
                    return;
                }
            }
        }
    }
    /* CMD+DELETE: deletes to beginning of text on line */
    else if(selector == @selector(deleteToBeginningOfLine:))
    {
        NSTextView *self = (NSTextView *)self_;
        NSString *text = self.string;
        NSRange selectedRange = self.selectedRange;
        NSRange lineRange = [text lineRangeForRange:selectedRange];
        if (lineRange.length != 0)
        {
            NSString *line = [text substringWithRange:lineRange];
            NSRange codeStartRange = [line rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
            
            if (codeStartRange.location != NSNotFound)
            {
                NSUInteger caretLocation = selectedRange.location - lineRange.location;
                if (caretLocation > codeStartRange.location)
                {
                    [self setSelectedRange:NSMakeRange(lineRange.location + codeStartRange.location, (caretLocation - codeStartRange.location))];
                    [self delete:nil];
                    return;
                }
            }
        }
    }
    
    return ((void (*)(id, SEL, SEL))original_doCommandBySelector)(self_, _cmd, selector);
}

+ (void) pluginDidLoad:(NSBundle *)plugin
{
    Class class = nil;
    Method originalMethod = nil;
    
    NSLog(@"%@ initializing...", NSStringFromClass([self class]));
    
    if (!(class = NSClassFromString(@"DVTSourceTextView")))
        goto failed;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(doCommandBySelector:))))
        goto failed;
    
    if (!(original_doCommandBySelector = method_setImplementation(originalMethod, (IMP)&doCommandBySelector)))
        goto failed;
    
    NSLog(@"%@ complete!", NSStringFromClass([self class]));
    return;
    
failed:
    NSLog(@"%@ failed. :(", NSStringFromClass([self class]));
}
@end
