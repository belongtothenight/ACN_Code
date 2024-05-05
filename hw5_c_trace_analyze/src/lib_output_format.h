/**
 * @file  output_format.h
 * @brief Output format struct for color printing (charactors)
 * Ref:
 * 1. https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
 * 2. https://stackoverflow.com/questions/37774983/clearing-the-screen-by-printing-a-character
 * 3. https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
*/

#ifndef OUTPUT_FORMAT_H
#define OUTPUT_FORMAT_H

//! @cond Doxygen_Suppress
/**
 * @brief Output format struct for color printing (charactors)
 * @details This struct contains all the color codes for printing in terminal
 */
typedef struct{
    /// @brief Styles
    struct Styles{
        const char *reset;        ///< reset
        const char *bold;         ///< bold
        const char *underline;    ///< underline
        const char *inverse;      ///< inverse
    } style;
    /// @brief Text colors
    struct Foreground{
        const char *black;        ///< black
        const char *red;          ///< red
        const char *green;        ///< green
        const char *yellow;       ///< yellow
        const char *blue;         ///< blue
        const char *magenta;      ///< magenta
        const char *cyan;         ///< cyan
        const char *white;        ///< white
    } foreground;
    /// @brief Background colors
    struct Background{
        const char *black;        ///< black
        const char *red;          ///< red
        const char *green;        ///< green
        const char *yellow;       ///< yellow
        const char *blue;         ///< blue
        const char *magenta;      ///< magenta
        const char *cyan;         ///< cyan
        const char *white;        ///< white
    } background;
    /// @brief Strong text colors
    struct Strong_Foreground{
        const char *black;        ///< black
        const char *red;          ///< red
        const char *green;        ///< green
        const char *yellow;       ///< yellow
        const char *blue;         ///< blue
        const char *magenta;      ///< magenta
        const char *cyan;         ///< cyan
        const char *white;        ///< white
    } strong_foreground;
    /// @brief Strong background colors
    struct Strong_Background{
        const char *black;        ///< black
        const char *red;          ///< red
        const char *green;        ///< green
        const char *yellow;       ///< yellow
        const char *blue;         ///< blue
        const char *magenta;      ///< magenta
        const char *cyan;         ///< cyan
        const char *white;        ///< white
    } strong_background;
    /// @brief Action
    struct Action{
        const char *reset_terminal;           ///< reset terminal
        const char *clear_screen_below;       ///< clear screen below
        const char *clear_screen_above;       ///< clear screen above
        const char *clear_screen_all;         ///< clear screen all
        const char *clear_screen_saved_lines; ///< clear screen saved lines
        const char *clear_selected_right;         ///< clear selected to right
        const char *clear_selected_left;          ///< clear selected to left
        const char *clear_selected_all;           ///< clear selected all
        const char *move_cursor_home;         ///< move cursor home
        const char *set_cursor_style_default; ///< set cursor style to default
        const char *set_cursor_style_blk_blk; ///< set cursor style to blinking block
        const char *set_cursor_style_std_blk; ///< set cursor style to steady block
        const char *set_cursor_style_blk_udl; ///< set cursor style to blinking underline
        const char *set_cursor_style_std_udl; ///< set cursor style to steady underline
        const char *set_cursor_style_blk_bar; ///< set cursor style to blinking bar
        const char *set_cursor_style_std_bar; ///< set cursor style to steady bar
        const char *set_warning_bell_volume_N;///< set warning bell volume to off
        const char *set_warning_bell_volume_L;///< set warning bell volume to low
        const char *set_warning_bell_volume_H;///< set warning bell volume to medium
        const char *Ps;                       ///< execution_times (used in the following commands)
        const char *insert_blank_char;        ///< insert blank char Ps times
        const char *move_cursor_up;           ///< move cursor up Ps lines
        const char *move_cursor_down;         ///< move cursor down Ps lines
        const char *move_cursor_forward;      ///< move cursor forward Ps chars
        const char *move_cursor_backward;     ///< move cursor backward Ps chars
        const char *move_cursor_next_line;    ///< move cursor to the beginning of the next line Ps lines down
        const char *move_cursor_previous_line;///< move cursor to the beginning of the previous line Ps lines up
        const char *insert_line;              ///< insert line Ps lines
        const char *delete_line;              ///< delete line Ps lines
        const char *delete_char;              ///< delete char Ps chars
        const char *scroll_up;                ///< scroll up Ps lines
        const char *scroll_down;              ///< scroll down Ps lines

    } action;
    /// @brief Status
    struct Status{
        const char *success;      ///< success
        const char *warning;      ///< warning
        const char *error;        ///< error
        const char *pass;         ///< pass
        const char *fail;         ///< fail
    } status;
} output_format;
//! @endcond

/**
 * @brief Get the format object, return the format struct with value assigned
 * @param pFormat pointer to the output_format struct
 * @param Ps execution times
 * @return void
*/
void get_format (output_format* pFormat, int Ps);

#endif
